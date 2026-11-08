package synapse.upi.queue.consumer;

public interface Consumer<T> {
  void consume(T message);
}
