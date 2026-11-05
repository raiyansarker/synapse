package synapse.upi.payment;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.math.BigDecimal;
import java.util.Map;
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
    Payment payment = Payment.accept("mina@city", "raiyan@city", new BigDecimal("10.00"), Map.of("note", "rent"));
    when(payments.start(
            eq("mina@city"),
            eq("raiyan@city"),
            eq(new BigDecimal("10.00")),
            eq(Map.of("note", "rent"))))
        .thenReturn(payment);

    mvc.perform(post("/payments")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "virtualAddress": "mina@city",
                  "amount": "10.00",
                  "payeeVirtualAddress": "raiyan@city",
                  "metadata": { "note": "rent" }
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.success").value(true))
        .andExpect(jsonPath("$.data.atomicId").value(payment.atomicId()))
        .andExpect(jsonPath("$.error").doesNotExist());
  }

  @Test
  void publishesWhenMetadataIsOmitted() throws Exception {
    Payment payment = Payment.accept("mina@city", "raiyan@city", BigDecimal.ONE, null);
    when(payments.start(eq("mina@city"), eq("raiyan@city"), eq(new BigDecimal("1")), eq(null)))
        .thenReturn(payment);

    mvc.perform(post("/payments")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "virtualAddress": "mina@city",
                  "amount": 1,
                  "payeeVirtualAddress": "raiyan@city"
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.atomicId").value(payment.atomicId()));
  }

  @Test
  void rejectsAVirtualAddressWithoutABank() throws Exception {
    mvc.perform(post("/payments")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "virtualAddress": "mina",
                  "amount": "10.00",
                  "payeeVirtualAddress": "raiyan@city"
                }
                """))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.success").value(false))
        .andExpect(jsonPath("$.error.detail").value("Validation failed"))
        .andExpect(jsonPath("$.error.reasons[0].field").value("virtualAddress"))
        .andExpect(jsonPath("$.error.reasons[0].message").value("must look like name@bank"));
  }

  @Test
  void rejectsAMissingPayeeVirtualAddress() throws Exception {
    mvc.perform(post("/payments")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "virtualAddress": "mina@city",
                  "amount": "10.00"
                }
                """))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.error.title").value("Bad Request"))
        .andExpect(jsonPath("$.error.reasons[0].field").value("payeeVirtualAddress"));
  }

  @Test
  void rejectsAnAmountThatIsNotPositive() throws Exception {
    mvc.perform(post("/payments")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "virtualAddress": "mina@city",
                  "amount": "0",
                  "payeeVirtualAddress": "raiyan@city"
                }
                """))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.error.reasons[0].field").value("amount"));
  }
}
