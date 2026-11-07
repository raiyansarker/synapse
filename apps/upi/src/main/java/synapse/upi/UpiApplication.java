package synapse.upi;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

@SpringBootApplication
@EnableJpaAuditing
public class UpiApplication {
  public static void main(String[] args) {
    SpringApplication.run(UpiApplication.class, args);
  }
}
