package synapse.bank.common.exception;

import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;

public class ForbiddenException extends HttpError {

  public ForbiddenException(String detail) {
    this(detail, List.of());
  }

  public ForbiddenException(String detail, List<Map<String, String>> reasons) {
    super(HttpStatus.FORBIDDEN, "Forbidden", detail, reasons);
  }
}
