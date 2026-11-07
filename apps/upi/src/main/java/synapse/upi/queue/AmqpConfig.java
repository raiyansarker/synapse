package synapse.upi.queue;

import org.springframework.amqp.support.converter.JacksonJsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class AmqpConfig {
  @Bean
  MessageConverter messageConverter() {
    return new JacksonJsonMessageConverter();
  }
}
