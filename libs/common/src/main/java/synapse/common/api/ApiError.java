package synapse.common.api;

import java.util.List;
import java.util.Map;
import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class ApiError {

  String title;
  String detail;
  @Builder.Default
  List<Map<String, String>> reasons = List.of();
}
