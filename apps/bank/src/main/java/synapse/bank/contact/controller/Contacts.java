package synapse.bank.contact.controller;

import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import synapse.bank.contact.ContactService;
import synapse.bank.contact.dto.ContactResponse;

@RestController
@RequestMapping("/api/users/{userId}/contacts")
@RequiredArgsConstructor
public class Contacts {

  private final ContactService contactService;

  @GetMapping
  public List<ContactResponse> list(
      @PathVariable
      String userId
  ) {
    return this.contactService.list(userId);
  }
}
