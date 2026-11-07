package synapse.upi.bank;

import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BankRepository extends JpaRepository<Bank, String> {
  Optional<Bank> findByIdentifier(String identifier);
}
