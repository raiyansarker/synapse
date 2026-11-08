package synapse.upi.queue.topology;

import org.springframework.amqp.core.Binding;
import org.springframework.amqp.core.BindingBuilder;
import org.springframework.amqp.core.ExchangeBuilder;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.core.QueueBuilder;
import org.springframework.amqp.core.TopicExchange;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class PayTopology {
  public static final String EXCHANGE = "pay";

  public static final String DEBIT_AUTHORIZATION_QUEUE       = "pay.debit_authorization";
  public static final String DEBIT_AUTHORIZATION_ROUTING_KEY = "pay.debit_authorization";

  public static final String DEAD_LETTER_QUEUE       = "pay.dead";
  public static final String DEAD_LETTER_ROUTING_KEY = "pay.dead";

  @Bean
  TopicExchange payExchange() {
    return ExchangeBuilder.topicExchange(EXCHANGE).durable(true).build();
  }

  @Bean
  Queue payDebitAuthorizationQueue() {
    return QueueBuilder.durable(DEBIT_AUTHORIZATION_QUEUE)
        .quorum()
        .build();
  }

  @Bean
  Binding payDebitAuthorizationBinding(Queue payDebitAuthorizationQueue, TopicExchange payExchange) {
    return BindingBuilder.bind(payDebitAuthorizationQueue).to(payExchange).with(DEBIT_AUTHORIZATION_ROUTING_KEY);
  }

  @Bean
  Queue payDeadLetterQueue() {
    return QueueBuilder.durable(DEAD_LETTER_QUEUE)
        .quorum()
        .build();
  }

  @Bean
  Binding payDeadLetterBinding(Queue payDeadLetterQueue, TopicExchange payExchange) {
    return BindingBuilder.bind(payDeadLetterQueue).to(payExchange).with(DEAD_LETTER_ROUTING_KEY);
  }
}
