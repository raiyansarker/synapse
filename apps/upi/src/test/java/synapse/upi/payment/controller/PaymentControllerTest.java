package synapse.upi.payment.controller;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.math.BigDecimal;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.ImportAutoConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import synapse.common.CommonHttpAutoConfiguration;
import synapse.upi.payment.Payment;
import synapse.upi.payment.statemachine.PaymentState;
import synapse.upi.payment.workflow.PaymentWorkflow;

@WebMvcTest(PaymentController.class)
@ImportAutoConfiguration(CommonHttpAutoConfiguration.class)
class PaymentControllerTest {

  @Autowired private MockMvc mvc;

  @MockitoBean private PaymentWorkflow payments;

  @Test
  void publishesAndReturnsTheAtomicIdInTheBody() throws Exception {
    ArgumentCaptor<Payment> published = ArgumentCaptor.forClass(Payment.class);
    when(payments.start(published.capture())).thenAnswer(invocation -> invocation.getArgument(0));

    mvc.perform(
            post("/api/pay")
                .contentType(MediaType.APPLICATION_JSON)
                .header("X-Request-Id", "req-1")
                .content(body("mina@city", "10.00", "raiyan@city")))
        .andExpect(status().isOk())
        .andExpect(header().string("X-Request-Id", "req-1"))
        .andExpect(jsonPath("$.success").value(true))
        .andExpect(jsonPath("$.data.atomicId").value(published.getValue().atomicId()))
        .andExpect(jsonPath("$.meta.requestId").value("req-1"))
        .andExpect(jsonPath("$.error").doesNotExist());

    Payment payment = published.getValue();
    assertEquals(PaymentState.ACCEPTED, payment.state());
    assertEquals("mina@city", payment.sva());
    assertEquals("raiyan@city", payment.rva());
    assertEquals(0, payment.amount().compareTo(new BigDecimal("10.00")));
  }

  @ParameterizedTest
  @CsvSource({
    "mina, 10.00, raiyan@city, sva",
    "mina@city, 10.00, raiyan, rva",
    "mina@, 10.00, raiyan@city, sva",
    "mina@city, 10.00, @city, rva"
  })
  void rejectsAnAddressWithoutABank(String sva, String amount, String rva, String field)
      throws Exception {
    mvc.perform(
            post("/api/pay")
                .contentType(MediaType.APPLICATION_JSON)
                .content(body(sva, amount, rva)))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.success").value(false))
        .andExpect(jsonPath("$.error.detail").value("Validation failed"))
        .andExpect(jsonPath("$.error.reasons[0].field").value(field))
        .andExpect(jsonPath("$.error.reasons[0].message").value("must look like name@bank"));
    verify(payments, never()).start(org.mockito.ArgumentMatchers.any());
  }

  @ParameterizedTest
  @CsvSource({"0", "-1"})
  void rejectsAnAmountThatIsNotPositive(String amount) throws Exception {
    mvc.perform(
            post("/api/pay")
                .contentType(MediaType.APPLICATION_JSON)
                .content(body("mina@city", amount, "raiyan@city")))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.error.reasons[0].field").value("amount"));
    verify(payments, never()).start(org.mockito.ArgumentMatchers.any());
  }

  @Test
  void rejectsAMissingReceiver() throws Exception {
    mvc.perform(
            post("/api/pay")
                .contentType(MediaType.APPLICATION_JSON)
                .content(
                    """
                    {"sva":"mina@city","amount":"10.00"}
                    """))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.error.title").value("Bad Request"))
        .andExpect(jsonPath("$.error.reasons[0].field").value("rva"));
  }

  @Test
  void rejectsAMalformedBody() throws Exception {
    mvc.perform(post("/api/pay").contentType(MediaType.APPLICATION_JSON).content("{"))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.error.title").value("Bad Request"))
        .andExpect(jsonPath("$.error.detail").value("Malformed request body"));
  }

  private static String body(String sva, String amount, String rva) {
    return """
    {"sva":"%s","amount":"%s","rva":"%s"}
    """
        .formatted(sva, amount, rva);
  }
}
