package synapse.upi.payment;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.math.BigDecimal;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.ImportAutoConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import synapse.common.CommonHttpAutoConfiguration;

@WebMvcTest(PaymentController.class)
@ImportAutoConfiguration(CommonHttpAutoConfiguration.class)
class PaymentControllerTest {

  @Autowired
  private MockMvc mvc;

  @MockitoBean
  private PaymentWorkflow payments;

  @Test
  void publishesAndReturnsTheAtomicIdInTheBody() throws Exception {
    Payment payment = Payment.accept("mina@city", "raiyan@city", new BigDecimal("10.00"));
    when(payments.start(eq("mina@city"), eq("raiyan@city"), eq(new BigDecimal("10.00"))))
        .thenReturn(payment);

    mvc.perform(post("/payments")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "payerVa": "mina@city",
                  "amount": "10.00",
                  "payeeVa": "raiyan@city"
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.success").value(true))
        .andExpect(jsonPath("$.data.atomicId").value(payment.atomicId()))
        .andExpect(jsonPath("$.error").doesNotExist());
  }

  @Test
  void rejectsAPayerVaWithoutABank() throws Exception {
    mvc.perform(post("/payments")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "payerVa": "mina",
                  "amount": "10.00",
                  "payeeVa": "raiyan@city"
                }
                """))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.success").value(false))
        .andExpect(jsonPath("$.error.detail").value("Validation failed"))
        .andExpect(jsonPath("$.error.reasons[0].field").value("payerVa"))
        .andExpect(jsonPath("$.error.reasons[0].message").value("must look like name@bank"));
  }

  @Test
  void rejectsAMissingPayeeVa() throws Exception {
    mvc.perform(post("/payments")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "payerVa": "mina@city",
                  "amount": "10.00"
                }
                """))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.error.title").value("Bad Request"))
        .andExpect(jsonPath("$.error.reasons[0].field").value("payeeVa"));
  }

  @Test
  void rejectsAnAmountThatIsNotPositive() throws Exception {
    mvc.perform(post("/payments")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "payerVa": "mina@city",
                  "amount": "0",
                  "payeeVa": "raiyan@city"
                }
                """))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.error.reasons[0].field").value("amount"));
  }
}
