package synapse.common.exception;

import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;

public class NotFoundException extends HttpError {

  public NotFoundException(String detail) {
    this(detail, List.of());
  }

  public NotFoundException(String detail, List<Map<String, String>> reasons) {
    super(HttpStatus.NOT_FOUND, "Not Found", detail, reasons);
  }
}
