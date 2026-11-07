package synapse.common;

import static org.hamcrest.Matchers.not;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.ImportAutoConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(SampleController.class)
@ImportAutoConfiguration(CommonHttpAutoConfiguration.class)
class CommonHttpTest {

  @Autowired private MockMvc mvc;

  @Test
  void wrapsASuccessfulBodyAndEchoesTheRequestId() throws Exception {
    mvc.perform(get("/items/100").header("X-Request-Id", "req-100"))
        .andExpect(status().isOk())
        .andExpect(header().string("X-Request-Id", "req-100"))
        .andExpect(jsonPath("$.success").value(true))
        .andExpect(jsonPath("$.data.id").value("100"))
        .andExpect(jsonPath("$.error").doesNotExist())
        .andExpect(jsonPath("$.meta.requestId").value("req-100"));
  }

  @Test
  void mintsARequestIdWhenTheHeaderIsMissing() throws Exception {
    mvc.perform(get("/items/100"))
        .andExpect(status().isOk())
        .andExpect(header().exists("X-Request-Id"))
        .andExpect(header().string("X-Request-Id", not("unknown")))
        .andExpect(jsonPath("$.meta.requestId").isNotEmpty())
        .andExpect(jsonPath("$.meta.requestId").value(not("unknown")));
  }

  @Test
  void leavesAnExistingEnvelopeAlone() throws Exception {
    mvc.perform(get("/envelope"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.success").value(true))
        .andExpect(jsonPath("$.data.id").value("wrapped"))
        .andExpect(jsonPath("$.meta.requestId").value("fixed"));
  }

  @Test
  void leavesHtmlAlone() throws Exception {
    mvc.perform(get("/html"))
        .andExpect(status().isOk())
        .andExpect(content().contentTypeCompatibleWith(MediaType.TEXT_HTML))
        .andExpect(content().string("<html><body>ok</body></html>"));
  }

  @Test
  void rendersNotFound() throws Exception {
    mvc.perform(get("/items/missing").header("X-Request-Id", "req-missing"))
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.success").value(false))
        .andExpect(jsonPath("$.data").doesNotExist())
        .andExpect(jsonPath("$.error.title").value("Not Found"))
        .andExpect(jsonPath("$.error.detail").value("Item missing was not found"))
        .andExpect(jsonPath("$.meta.requestId").value("req-missing"));
  }

  @Test
  void rendersValidationErrors() throws Exception {
    mvc.perform(post("/items").contentType(MediaType.APPLICATION_JSON).content("{}"))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.success").value(false))
        .andExpect(jsonPath("$.error.title").value("Bad Request"))
        .andExpect(jsonPath("$.error.detail").value("Validation failed"))
        .andExpect(jsonPath("$.error.reasons[0].field").value("name"));
  }

  @Test
  void rendersAMalformedBody() throws Exception {
    mvc.perform(post("/items").contentType(MediaType.APPLICATION_JSON).content("{"))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.error.title").value("Bad Request"))
        .andExpect(jsonPath("$.error.detail").value("Malformed request body"));
  }

  @Test
  void rendersMethodNotAllowed() throws Exception {
    mvc.perform(post("/items/100"))
        .andExpect(status().isMethodNotAllowed())
        .andExpect(jsonPath("$.error.title").value("Method Not Allowed"));
  }

  @Test
  void hidesUnexpectedFailures() throws Exception {
    mvc.perform(get("/items/boom"))
        .andExpect(status().isInternalServerError())
        .andExpect(jsonPath("$.error.title").value("Internal Server Error"))
        .andExpect(jsonPath("$.error.detail").value("An unexpected error occurred"))
        .andExpect(jsonPath("$.error.detail").value(not("boom")));
  }
}
