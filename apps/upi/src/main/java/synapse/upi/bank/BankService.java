package synapse.upi.bank;

import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class BankService {
  private final BankRepository banks;

  public boolean exist(List<String> identifiers) {
    Set<String> unique = Set.copyOf(identifiers);
    Set<String> found =
        banks.findByIdentifierIn(unique).stream()
            .filter(Bank::isEnabled)
            .map(Bank::getIdentifier)
            .collect(Collectors.toSet());
    return found.containsAll(unique);
  }

  public void seed(
      String identifier,
      String baseUrl
  ) {
    if (banks.findByIdentifier(identifier).isEmpty()) {
      banks.save(Bank.create(identifier, baseUrl));
    }
  }
}
