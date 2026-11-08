package synapse.upi.queue;

import org.springframework.amqp.core.Message;
import org.springframework.amqp.core.MessageProperties;
import org.springframework.amqp.support.converter.JacksonJsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConversionException;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import synapse.upi.queue.retry.MessageContextHolder;

@Configuration
public class AmqpConfig {

  @Bean
  MessageConverter messageConverter() {
    JacksonJsonMessageConverter delegate = new JacksonJsonMessageConverter();
    return new MessageConverter() {
      @Override
      public Message toMessage(Object object, MessageProperties messageProperties) throws MessageConversionException {
        return delegate.toMessage(object, messageProperties);
      }

      @Override
      public Object fromMessage(Message message) throws MessageConversionException {
        MessageContextHolder.setCurrentMessage(message);
        return delegate.fromMessage(message);
      }
    };
  }
}
