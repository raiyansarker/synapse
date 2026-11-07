package synapse.common.exception;

import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;

public class ConflictException extends HttpError {

  public ConflictException(String title, String detail) {
    this(title, detail, List.of());
  }

  public ConflictException(String title, String detail, List<Map<String, String>> reasons) {
    super(HttpStatus.CONFLICT, title, detail, reasons);
  }
}
