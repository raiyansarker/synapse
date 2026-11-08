package synapse.upi.pay.mock;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertInstanceOf;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.math.BigDecimal;
import java.time.Duration;
import org.junit.jupiter.api.Test;
import synapse.upi.ledger.Ledger;
import synapse.upi.pay.ack.impl.MockAckGateway;
import synapse.upi.pay.ack.interfaces.AckResult;
import synapse.upi.pay.credit.impl.MockCreditGateway;
import synapse.upi.pay.credit.interfaces.CreditResult;
import synapse.upi.pay.debit.impl.MockDebitGateway;
import synapse.upi.pay.debit.interfaces.DebitResult;
import synapse.upi.pay.mock.MockOutcomes.Mode;
import synapse.upi.pay.reversal.impl.MockReversalGateway;
import synapse.upi.pay.reversal.interfaces.ReversalResult;

class MockOutcomesTest {

  @Test
  void defaultsApproveEveryCall() {
    MockOutcomes outcomes = outcomes();
    Ledger entry = entry();

    assertInstanceOf(DebitResult.Approved.class, new MockDebitGateway(outcomes).debit(entry));
    assertInstanceOf(CreditResult.Approved.class, new MockCreditGateway(outcomes).credit(entry));
    assertInstanceOf(AckResult.Succeeded.class, new MockAckGateway(outcomes).acknowledge(entry));
    assertInstanceOf(ReversalResult.Reversed.class, new MockReversalGateway(outcomes).reverse(entry));
  }

  @Test
  void declineIsSticky() {
    MockOutcomes outcomes = outcomes();
    outcomes.setDebit(Mode.DECLINE);
    outcomes.setCredit(Mode.DECLINE);
    outcomes.setAck(Mode.DECLINE);
    outcomes.setReversal(Mode.DECLINE);
    Ledger entry = entry();

    assertEquals("INSUFFICIENT_FUNDS",
        assertInstanceOf(DebitResult.Declined.class, new MockDebitGateway(outcomes).debit(entry))
            .reasonCode());
    assertEquals("ACCOUNT_CLOSED",
        assertInstanceOf(CreditResult.Declined.class, new MockCreditGateway(outcomes).credit(entry))
            .reasonCode());
    assertEquals("NOTIFY_REJECTED",
        assertInstanceOf(AckResult.Failed.class, new MockAckGateway(outcomes).acknowledge(entry))
            .reasonCode());
    assertEquals("REVERSE_REJECTED",
        assertInstanceOf(ReversalResult.Failed.class, new MockReversalGateway(outcomes).reverse(entry))
            .reasonCode());
  }

  @Test
  void transientAlwaysThrows() {
    MockOutcomes outcomes = outcomes();
    outcomes.setDebit(Mode.TRANSIENT);
    outcomes.setCredit(Mode.APPROVE);

    Ledger entry = entry();
    assertThrows(RuntimeException.class, () -> new MockDebitGateway(outcomes).debit(entry));
    assertInstanceOf(CreditResult.Approved.class, new MockCreditGateway(outcomes).credit(entry));
  }

  private static MockOutcomes outcomes() {
    MockOutcomes outcomes = new MockOutcomes();
    outcomes.setDelay(Duration.ZERO);
    return outcomes;
  }

  private static Ledger entry() {
    return Ledger.accepted("wow@brac", "bruh@city", new BigDecimal("10.00"));
  }
}
