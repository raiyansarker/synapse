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

  public void publish(PayId payId) {
    rabbit.convertAndSend(PayTopology.EXCHANGE, PayTopology.DEBIT_AUTHORIZATION_ROUTING_KEY, payId);
  }
}
