package synapse.common.exception;

import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;

public class ServiceUnavailableException extends HttpError {

  public ServiceUnavailableException(String title, String detail) {
    this(title, detail, List.of());
  }

  public ServiceUnavailableException(
      String title, String detail, List<Map<String, String>> reasons) {
    super(HttpStatus.SERVICE_UNAVAILABLE, title, detail, reasons);
  }
}
