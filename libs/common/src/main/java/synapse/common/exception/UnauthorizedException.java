package synapse.common.exception;

import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;

public class UnauthorizedException extends HttpError {

  public UnauthorizedException(String title, String detail) {
    this(title, detail, List.of());
  }

  public UnauthorizedException(String title, String detail, List<Map<String, String>> reasons) {
    super(HttpStatus.UNAUTHORIZED, title, detail, reasons);
  }
}
