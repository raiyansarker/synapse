package synapse.upi.pay.queue;

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
  public static final String QUEUE = "pay.accepted";
  public static final String ROUTING_KEY = "pay.accepted";

  @Bean
  TopicExchange payExchange() {
    return ExchangeBuilder.topicExchange(EXCHANGE).durable(true).build();
  }

  @Bean
  Queue payAcceptedQueue() {
    return QueueBuilder.durable(QUEUE).build();
  }

  @Bean
  Binding payAcceptedBinding(Queue payAcceptedQueue, TopicExchange payExchange) {
    return BindingBuilder.bind(payAcceptedQueue).to(payExchange).with(ROUTING_KEY);
  }
}
