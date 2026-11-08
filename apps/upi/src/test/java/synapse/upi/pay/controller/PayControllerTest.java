package synapse.upi.pay.controller;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.math.BigDecimal;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.ImportAutoConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import synapse.common.CommonHttpAutoConfiguration;
import synapse.upi.bank.BankService;
import synapse.upi.ledger.PaymentState;
import synapse.upi.pay.PayService;

@WebMvcTest(Pay.class)
@ImportAutoConfiguration(CommonHttpAutoConfiguration.class)
class PayControllerTest {

  @Autowired
  private MockMvc mvc;

  @MockitoBean
  private PayService payService;

  @MockitoBean
  private BankService bankService;

  @Test
  void acceptPayReturnsIdempotencyKey() throws Exception {
    when(bankService.exist(anyList())).thenReturn(true);
    when(payService.accept(any())).thenReturn("tx-1");

    mvc.perform(
            post("/api/pay")
                .contentType(MediaType.APPLICATION_JSON)
                .header("X-Request-Id", "req-1")
                .content(
                    """
                    {"sva":"wow@brac","rva":"bruh@city","amount":99.99}
                    """
                )
        )
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.success").value(true))
        .andExpect(jsonPath("$.data.idempotencyKey").value("tx-1"))
        .andExpect(jsonPath("$.meta.requestId").value("req-1"));
  }

  @Test
  void acceptPayRejectsUnknownBanks() throws Exception {
    when(bankService.exist(anyList())).thenReturn(false);

    mvc.perform(
            post("/api/pay")
                .contentType(MediaType.APPLICATION_JSON)
                .header("X-Request-Id", "req-banks")
                .content(
                    """
                    {"sva":"wow@brac","rva":"bruh@city","amount":99.99}
                    """
                )
        )
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.success").value(false))
        .andExpect(jsonPath("$.error.title").value("Bank not found"));

    verify(payService, never()).accept(any());
  }

  @Test
  void getPayStateReturnsCurrentState() throws Exception {
    when(payService.getPayState("tx-1")).thenReturn(Optional.of(PaymentState.DEBIT_AUTHORIZED));

    mvc.perform(get("/api/pay/tx-1").header("X-Request-Id", "req-state"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.success").value(true))
        .andExpect(jsonPath("$.data.state").value("DEBIT_AUTHORIZED"));
  }

  @Test
  void getPayStateReturnsNotFoundWhenMissing() throws Exception {
    when(payService.getPayState("missing")).thenReturn(Optional.empty());

    mvc.perform(get("/api/pay/missing").header("X-Request-Id", "req-missing"))
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.success").value(false))
        .andExpect(jsonPath("$.error.title").value("Transaction not found"));
  }
}
