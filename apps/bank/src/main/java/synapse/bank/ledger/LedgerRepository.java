package synapse.bank.ledger;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface LedgerRepository extends JpaRepository<Ledger, String> {
  List<Ledger> findByAccountIdOrderByCreatedAtDesc(String accountId);

  Optional<Ledger> findByReference(String reference);
}
