package synapse.upi.pay;

import java.util.Optional;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import lombok.RequiredArgsConstructor;
import synapse.upi.ledger.Ledger;
import synapse.upi.ledger.LedgerRepository;
import synapse.upi.ledger.PaymentState;
import synapse.upi.pay.dto.AcceptPayRequest;
import synapse.upi.queue.message.PayId;
import synapse.upi.queue.producer.PayProducer;

@Service
@RequiredArgsConstructor
public class PayService {
  private final LedgerRepository ledger;
  private final PayProducer producer;

  @Transactional
  public String accept(AcceptPayRequest request) {
    Ledger transaction =
        ledger.save(
            Ledger.accepted(
                request.sva(),
                request.rva(),
                request.amount()
            )
        );

    producer.publishDebitAuthorization(new PayId(transaction.getId()));

    return transaction.getId();
  }

  public Optional<PaymentState> getPayState(String id) {
    return this.ledger.findById(id).map(entry -> entry.getState());
  }
}
