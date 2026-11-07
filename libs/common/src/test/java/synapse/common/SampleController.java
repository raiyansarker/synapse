package synapse.common;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import java.time.Instant;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;
import synapse.common.api.ApiMeta;
import synapse.common.api.ApiResponse;
import synapse.common.exception.NotFoundException;

@RestController
class SampleController {

  @GetMapping("/items/{id}")
  Item get(@PathVariable String id) {
    if ("missing".equals(id)) {
      throw new NotFoundException("Item missing was not found");
    }
    if ("boom".equals(id)) {
      throw new IllegalStateException("boom");
    }
    return new Item(id);
  }

  @PostMapping("/items")
  Item create(@Valid @RequestBody CreateRequest request) {
    return new Item(request.name());
  }

  @GetMapping("/envelope")
  ApiResponse<Item> alreadyWrapped() {
    return ApiResponse.ok(
        new Item("wrapped"), ApiMeta.builder().requestId("fixed").timestamp(Instant.EPOCH).build());
  }

  @GetMapping(value = "/html", produces = MediaType.TEXT_HTML_VALUE)
  String html() {
    return "<html><body>ok</body></html>";
  }

  record Item(String id) {}

  record CreateRequest(@NotBlank String name) {}
}
