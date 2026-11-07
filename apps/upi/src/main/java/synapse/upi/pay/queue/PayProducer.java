package synapse.upi.pay.queue;

import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.stereotype.Service;

@Service
public class PayProducer {
  private final RabbitTemplate rabbit;

  public PayProducer(RabbitTemplate rabbit) {
    this.rabbit = rabbit;
  }

  public void publish(AcceptedPay pay) {
    rabbit.convertAndSend(PayTopology.EXCHANGE, PayTopology.ROUTING_KEY, pay);
  }
}
