package synapse.common.api;

import java.time.Instant;
import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class ApiMeta {

  String requestId;
  Instant timestamp;
}
