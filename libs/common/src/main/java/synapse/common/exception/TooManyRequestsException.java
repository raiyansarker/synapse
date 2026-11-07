package synapse.common.exception;

import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;

public class TooManyRequestsException extends HttpError {

  public TooManyRequestsException(String title, String detail) {
    this(title, detail, List.of());
  }

  public TooManyRequestsException(String title, String detail, List<Map<String, String>> reasons) {
    super(HttpStatus.TOO_MANY_REQUESTS, title, detail, reasons);
  }
}
