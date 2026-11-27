package synapse.bank.contact;

import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import synapse.bank.contact.dto.ContactResponse;
import synapse.bank.user.User;
import synapse.bank.user.UserRepository;
import synapse.common.VirtualAddress;
import synapse.common.exception.NotFoundException;

@Service
@RequiredArgsConstructor
public class ContactService {
  private final ContactRepository contacts;
  private final UserRepository users;

  @Transactional
  public Contact save(String ownerId, String virtualAddress) {
    User owner = findUser(ownerId);
    String normalized = VirtualAddress.parse(virtualAddress).toString();
    return this.contacts
        .findByOwnerIdAndVirtualAddress(owner.getId(), normalized)
        .orElseGet(() -> this.contacts.save(Contact.of(owner, normalized)));
  }

  @Transactional(readOnly = true)
  public List<ContactResponse> list(String ownerId) {
    User owner = findUser(ownerId);
    return this.contacts.findByOwnerIdOrderByCreatedAtDesc(owner.getId()).stream()
        .map(ContactService::toResponse)
        .toList();
  }

  private User findUser(String userId) {
    return this.users
        .findById(userId)
        .orElseThrow(() -> new NotFoundException("User not found", "No user exists with id " + userId));
  }

  private static ContactResponse toResponse(Contact contact) {
    return new ContactResponse(contact.getId(), contact.getVirtualAddress(), contact.getCreatedAt());
  }
}
