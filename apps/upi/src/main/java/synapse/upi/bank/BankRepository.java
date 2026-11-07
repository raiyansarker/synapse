package synapse.upi.bank;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BankRepository extends JpaRepository<Bank, String> {
  Optional<Bank> findByIdentifier(String identifier);

  List<Bank> findByIdentifierIn(Collection<String> identifiers);
}
