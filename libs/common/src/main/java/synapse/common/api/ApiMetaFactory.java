package synapse.common.api;

import java.time.Instant;
import org.springframework.stereotype.Component;
import synapse.common.request.RequestContext;

@Component
public class ApiMetaFactory {

  public ApiMeta current() {
    return ApiMeta.builder()
        .requestId(RequestContext.getRequestId())
        .timestamp(Instant.now())
        .build();
  }
}
