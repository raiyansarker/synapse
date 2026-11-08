package synapse.upi.queue.retry;

import org.springframework.amqp.core.Message;

public final class MessageContextHolder {

  private static final ThreadLocal<Message> CURRENT_MESSAGE = new ThreadLocal<>();

  private MessageContextHolder() {}

  public static void setCurrentMessage(Message message) {
    CURRENT_MESSAGE.set(message);
  }

  public static Message getCurrentMessage() {
    return CURRENT_MESSAGE.get();
  }

  public static void clear() {
    CURRENT_MESSAGE.remove();
  }
}
