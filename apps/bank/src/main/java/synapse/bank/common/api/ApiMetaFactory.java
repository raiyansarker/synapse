package synapse.bank.common.api;

import java.time.Instant;
import org.springframework.stereotype.Component;
import synapse.bank.common.request.RequestContext;

@Component
public class ApiMetaFactory {

  public ApiMeta current() {
    return ApiMeta.builder()
        .requestId(RequestContext.getRequestId())
        .timestamp(Instant.now())
        .build();
  }
}
