package synapse.common.exception;

import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;

public class TooManyRequestsException extends HttpError {

  public TooManyRequestsException(String detail) {
    this(detail, List.of());
  }

  public TooManyRequestsException(String detail, List<Map<String, String>> reasons) {
    super(HttpStatus.TOO_MANY_REQUESTS, "Too Many Requests", detail, reasons);
  }
}
