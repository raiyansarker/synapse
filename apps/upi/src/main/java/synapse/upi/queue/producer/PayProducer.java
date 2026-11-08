package synapse.upi.queue.producer;

import lombok.RequiredArgsConstructor;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.stereotype.Service;
import synapse.upi.queue.message.PayId;
import synapse.upi.queue.topology.PayTopology;

@Service
@RequiredArgsConstructor
public class PayProducer {
  private final RabbitTemplate rabbit;

  public void publishDebitAuthorization(PayId payId) {
    send(PayTopology.DEBIT_AUTHORIZATION_ROUTING_KEY, payId);
  }

  public void publishCreditAuthorization(PayId payId) {
    send(PayTopology.CREDIT_AUTHORIZATION_ROUTING_KEY, payId);
  }

  public void publishAcknowledgment(PayId payId) {
    send(PayTopology.ACKNOWLEDGMENT_ROUTING_KEY, payId);
  }

  public void publishReversal(PayId payId) {
    send(PayTopology.REVERSAL_ROUTING_KEY, payId);
  }

  private void send(String routingKey, PayId payId) {
    rabbit.convertAndSend(PayTopology.EXCHANGE, routingKey, payId);
  }
}
