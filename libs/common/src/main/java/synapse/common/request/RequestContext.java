package synapse.common.request;

import java.util.Optional;
import java.util.UUID;

public final class RequestContext {

  private static final ThreadLocal<String> REQUEST_ID = new ThreadLocal<>();

  private RequestContext() {}

  public static void init(String requestId) {
    REQUEST_ID.set(
        requestId == null || requestId.isBlank() ? UUID.randomUUID().toString() : requestId);
  }

  public static String getRequestId() {
    return Optional.ofNullable(REQUEST_ID.get()).orElse("unknown");
  }

  public static void clear() {
    REQUEST_ID.remove();
  }
}
