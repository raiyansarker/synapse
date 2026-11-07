package synapse.common.exception;

import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;

public class NotFoundException extends HttpError {

  public NotFoundException(String title, String detail) {
    this(title, detail, List.of());
  }

  public NotFoundException(String title, String detail, List<Map<String, String>> reasons) {
    super(HttpStatus.NOT_FOUND, title, detail, reasons);
  }
}
