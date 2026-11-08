package synapse.upi;

import org.junit.jupiter.api.Test;

/**
 * Full {@code @SpringBootTest} needs live Postgres and RabbitMQ. Prefer the focused unit /
 * {@code @WebMvcTest} suites under {@code ledger}, {@code pay}, and {@code queue}.
 */
class UpiApplicationTests {

  @Test
  void placeholderKeepsTheTestSourceSetAlive() {}
}
