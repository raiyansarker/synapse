package synapse.bank.demo;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import synapse.common.exception.NotFoundException;

/**
 * Example of the shared HTTP library. A returned account is wrapped by the library.
 * The id {@code missing} throws {@link NotFoundException}, which the library renders as an error.
 */
@RestController
@RequestMapping("/demo/accounts")
public class DemoController {

  @GetMapping("/{id}")
  public Account get(@PathVariable String id) {
    if ("missing".equals(id)) {
      throw new NotFoundException("Account missing was not found");
    }
    return new Account(id, "city");
  }

  public record Account(String id, String bank) {}
}
