package synapse.common.exception;

import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;

public class ForbiddenException extends HttpError {

  public ForbiddenException(String title, String detail) {
    this(title, detail, List.of());
  }

  public ForbiddenException(String title, String detail, List<Map<String, String>> reasons) {
    super(HttpStatus.FORBIDDEN, title, detail, reasons);
  }
}
