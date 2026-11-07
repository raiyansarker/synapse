package synapse.common.exception;

import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;

public class BadRequestException extends HttpError {

  public BadRequestException(String title, String detail) {
    this(title, detail, List.of());
  }

  public BadRequestException(String title, String detail, List<Map<String, String>> reasons) {
    super(HttpStatus.BAD_REQUEST, title, detail, reasons);
  }
}
