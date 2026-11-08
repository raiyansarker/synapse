package synapse.upi.pay.mock;

import java.time.Duration;
import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * Fixed outcome for each mock bank call. Defaults to approve after {@link #delay}.
 *
 * <p>Set {@code upi.mock.debit=decline} (or {@code transient}) to force that result every time.
 * Tests can also call the setters on this bean. {@code upi.mock.delay=0} skips the pause.
 */
@Component
@ConfigurationProperties(prefix = "upi.mock")
@Getter
@Setter
public class MockOutcomes {

  public enum Mode {
    APPROVE,
    DECLINE,
    TRANSIENT
  }

  private Mode debit = Mode.APPROVE;
  private Mode credit = Mode.APPROVE;
  private Mode ack = Mode.APPROVE;
  private Mode reversal = Mode.APPROVE;
  private Duration delay = Duration.ofMillis(1500);

  public void pause() {
    if (delay == null || delay.isZero() || delay.isNegative()) {
      return;
    }
    try {
      Thread.sleep(delay.toMillis());
    } catch (InterruptedException ex) {
      Thread.currentThread().interrupt();
    }
  }
}
