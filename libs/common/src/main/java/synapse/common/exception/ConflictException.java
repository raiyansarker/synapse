package synapse.common.exception;

import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;

public class ConflictException extends HttpError {

  public ConflictException(String detail) {
    this(detail, List.of());
  }

  public ConflictException(String detail, List<Map<String, String>> reasons) {
    super(HttpStatus.CONFLICT, "Conflict", detail, reasons);
  }
}
