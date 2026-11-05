package synapse.upi.payment;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.math.BigDecimal;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.ImportAutoConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import synapse.common.CommonHttpAutoConfiguration;
import synapse.upi.payment.workflow.PaymentWorkflow;

@WebMvcTest(PaymentController.class)
@ImportAutoConfiguration(CommonHttpAutoConfiguration.class)
class PaymentControllerTest {

  @Autowired
  private MockMvc mvc;

  @MockitoBean
  private PaymentWorkflow payments;

  @Test
  void publishesAndReturnsTheAtomicIdInTheBody() throws Exception {
    ArgumentCaptor<Payment> published = ArgumentCaptor.forClass(Payment.class);
    when(payments.start(published.capture())).thenAnswer(invocation -> invocation.getArgument(0));

    mvc.perform(post("/payments")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "sva": "mina@city",
                  "amount": "10.00",
                  "rva": "raiyan@city"
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.success").value(true))
        .andExpect(jsonPath("$.data.atomicId").value(published.getValue().atomicId()))
        .andExpect(jsonPath("$.error").doesNotExist());

    Payment payment = published.getValue();
    assertEquals("mina@city", payment.sva());
    assertEquals("raiyan@city", payment.rva());
    assertEquals(0, payment.amount().compareTo(new BigDecimal("10.00")));
  }

  @Test
  void rejectsAnSvaWithoutABank() throws Exception {
    mvc.perform(post("/payments")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "sva": "mina",
                  "amount": "10.00",
                  "rva": "raiyan@city"
                }
                """))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.success").value(false))
        .andExpect(jsonPath("$.error.detail").value("Validation failed"))
        .andExpect(jsonPath("$.error.reasons[0].field").value("sva"))
        .andExpect(jsonPath("$.error.reasons[0].message").value("must look like name@bank"));
  }

  @Test
  void rejectsAMissingRva() throws Exception {
    mvc.perform(post("/payments")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "sva": "mina@city",
                  "amount": "10.00"
                }
                """))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.error.title").value("Bad Request"))
        .andExpect(jsonPath("$.error.reasons[0].field").value("rva"));
  }

  @Test
  void rejectsAnAmountThatIsNotPositive() throws Exception {
    mvc.perform(post("/payments")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "sva": "mina@city",
                  "amount": "0",
                  "rva": "raiyan@city"
                }
                """))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.error.reasons[0].field").value("amount"));
  }
}
