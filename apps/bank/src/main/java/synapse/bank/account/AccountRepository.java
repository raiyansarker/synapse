package synapse.bank.account;

import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AccountRepository extends JpaRepository<Account, String> {
  Optional<Account> findByVirtualAddress(String virtualAddress);

  boolean existsByVirtualAddress(String virtualAddress);
}
