package synapse.bank.demo;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.ImportAutoConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.test.web.servlet.MockMvc;
import synapse.common.CommonHttpAutoConfiguration;

@WebMvcTest(DemoController.class)
@ImportAutoConfiguration(CommonHttpAutoConfiguration.class)
class DemoControllerTest {

  @Autowired private MockMvc mvc;

  @Test
  void wrapsAFoundAccount() throws Exception {
    mvc.perform(get("/demo/accounts/100").header("X-Request-Id", "req-100"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.success").value(true))
        .andExpect(jsonPath("$.data.id").value("100"))
        .andExpect(jsonPath("$.data.bank").value("city"))
        .andExpect(jsonPath("$.error").doesNotExist())
        .andExpect(jsonPath("$.meta.requestId").value("req-100"));
  }

  @Test
  void rendersAMissingAccountAsNotFound() throws Exception {
    mvc.perform(get("/demo/accounts/missing").header("X-Request-Id", "req-missing"))
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.success").value(false))
        .andExpect(jsonPath("$.data").doesNotExist())
        .andExpect(jsonPath("$.error.title").value("Not Found"))
        .andExpect(jsonPath("$.error.detail").value("Account missing was not found"))
        .andExpect(jsonPath("$.meta.requestId").value("req-missing"));
  }
}
