package synapse.upi.admin.controller;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.math.BigDecimal;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.ImportAutoConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.data.domain.Sort;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import synapse.common.CommonHttpAutoConfiguration;
import synapse.upi.ledger.Ledger;
import synapse.upi.ledger.LedgerRepository;

@WebMvcTest(AdminPaymentsController.class)
@ImportAutoConfiguration(CommonHttpAutoConfiguration.class)
class AdminPaymentsControllerTest {

  @Autowired
  private MockMvc mvc;

  @MockitoBean
  private LedgerRepository ledgerRepository;

  @Test
  void listPaymentsReturnsLedgerRecordsInEnvelope() throws Exception {
    Ledger ledger = Ledger.accepted("payer@city", "payee@brac", new BigDecimal("150.00"));
    when(ledgerRepository.findAll(any(Sort.class))).thenReturn(List.of(ledger));

    mvc.perform(
            get("/api/admin/payments")
                .header("X-Request-Id", "admin-req-1")
        )
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.success").value(true))
        .andExpect(jsonPath("$.data[0].id").value(ledger.getId()))
        .andExpect(jsonPath("$.data[0].sva").value("payer@city"))
        .andExpect(jsonPath("$.data[0].rva").value("payee@brac"))
        .andExpect(jsonPath("$.data[0].amount").value(150.00))
        .andExpect(jsonPath("$.data[0].state").value("ACCEPTED"))
        .andExpect(jsonPath("$.meta.requestId").value("admin-req-1"));
  }
}
