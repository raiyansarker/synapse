package synapse.upi.admin.controller;

import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Sort;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import synapse.upi.admin.dto.AdminPaymentDto;
import synapse.upi.ledger.LedgerRepository;

@RestController
@RequestMapping("/api/admin/payments")
@RequiredArgsConstructor
public class AdminPaymentsController {
  private final LedgerRepository ledgerRepository;

  @GetMapping
  public List<AdminPaymentDto> listPayments() {
    return ledgerRepository.findAll(Sort.by(Sort.Direction.DESC, "createdAt"))
        .stream()
        .map(AdminPaymentDto::from)
        .toList();
  }
}
