package synapse.upi.bank;

import lombok.RequiredArgsConstructor;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/**
 * Seeds demo banks when explicitly enabled. Does not run on a normal boot.
 *
 * <pre>
 * ./gradlew bootRun --args='--upi.banks.seed=true'
 * </pre>
 */
@Component
@ConditionalOnProperty(prefix = "upi.banks", name = "seed", havingValue = "true")
@RequiredArgsConstructor
public class BankSeeder implements ApplicationRunner {
  private final BankService banks;

  @Override
  public void run(ApplicationArguments args) {
    banks.seed("city", "http://localhost:9090");
    banks.seed("ucb", "http://localhost:9091");
    banks.seed("brac", "http://localhost:9092");
  }
}
