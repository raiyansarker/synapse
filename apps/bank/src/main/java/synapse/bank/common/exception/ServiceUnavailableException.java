package synapse.bank.common.exception;

import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;

public class ServiceUnavailableException extends HttpError {

  public ServiceUnavailableException(String detail) {
    this(detail, List.of());
  }

  public ServiceUnavailableException(String detail, List<Map<String, String>> reasons) {
    super(HttpStatus.SERVICE_UNAVAILABLE, "Service Unavailable", detail, reasons);
  }
}
