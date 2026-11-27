package synapse.bank.contact;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ContactRepository extends JpaRepository<Contact, String> {
  List<Contact> findByOwnerIdOrderByCreatedAtDesc(String ownerId);

  Optional<Contact> findByOwnerIdAndVirtualAddress(String ownerId, String virtualAddress);
}
