package synapse.common.exception;

import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;

public class UnauthorizedException extends HttpError {

  public UnauthorizedException(String detail) {
    this(detail, List.of());
  }

  public UnauthorizedException(String detail, List<Map<String, String>> reasons) {
    super(HttpStatus.UNAUTHORIZED, "Unauthorized", detail, reasons);
  }
}
