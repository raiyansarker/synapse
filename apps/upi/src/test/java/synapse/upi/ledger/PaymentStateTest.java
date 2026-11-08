package synapse.upi.ledger;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;

class PaymentStateTest {

  @Test
  void debitConsumerOnlyAcceptsAcceptedOrPending() {
    assertTrue(PaymentState.ACCEPTED.awaitingDebitAuthorization());
    assertTrue(PaymentState.DEBIT_AUTHORIZATION_PENDING.awaitingDebitAuthorization());
    assertFalse(PaymentState.DEBIT_AUTHORIZED.awaitingDebitAuthorization());
    assertFalse(PaymentState.DEBIT_DECLINED.awaitingDebitAuthorization());
    assertFalse(PaymentState.CREDIT_AUTHORIZATION_PENDING.awaitingDebitAuthorization());
  }

  @Test
  void creditConsumerOnlyAcceptsDebitAuthorizedOrCreditPending() {
    assertTrue(PaymentState.DEBIT_AUTHORIZED.awaitingCreditAuthorization());
    assertTrue(PaymentState.CREDIT_AUTHORIZATION_PENDING.awaitingCreditAuthorization());
    assertFalse(PaymentState.ACCEPTED.awaitingCreditAuthorization());
    assertFalse(PaymentState.CREDIT_AUTHORIZED.awaitingCreditAuthorization());
  }

  @Test
  void acknowledgmentConsumerOnlyAcceptsCreditAuthorizedOrAcknowledging() {
    assertTrue(PaymentState.CREDIT_AUTHORIZED.awaitingAcknowledgment());
    assertTrue(PaymentState.ACKNOWLEDGING.awaitingAcknowledgment());
    assertFalse(PaymentState.DEBIT_AUTHORIZED.awaitingAcknowledgment());
    assertFalse(PaymentState.COMPLETED.awaitingAcknowledgment());
  }

  @Test
  void reversalConsumerOnlyAcceptsReversalPending() {
    assertTrue(PaymentState.REVERSAL_PENDING.awaitingReversal());
    assertFalse(PaymentState.CREDIT_AUTHORIZED.awaitingReversal());
    assertFalse(PaymentState.REVERSED.awaitingReversal());
  }

  @ParameterizedTest
  @EnumSource(
      value = PaymentState.class,
      names = {
          "DEBIT_DECLINED",
          "DEBIT_AUTHORIZATION_FAILED",
          "COMPLETED",
          "REVERSED",
          "REVERSAL_FAILED"
      }
  )
  void marksTerminalOutcomes(PaymentState state) {
    assertTrue(state.terminal());
  }

  @ParameterizedTest
  @EnumSource(
      value = PaymentState.class,
      names = {
          "ACCEPTED",
          "DEBIT_AUTHORIZATION_PENDING",
          "DEBIT_AUTHORIZED",
          "CREDIT_AUTHORIZATION_PENDING",
          "CREDIT_AUTHORIZED",
          "ACKNOWLEDGING",
          "REVERSAL_PENDING"
      }
  )
  void marksInFlightStatesAsNonTerminal(PaymentState state) {
    assertFalse(state.terminal());
  }
}
