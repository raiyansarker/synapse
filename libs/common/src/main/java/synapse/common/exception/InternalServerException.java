package synapse.common.exception;

import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;

public class InternalServerException extends HttpError {

  public InternalServerException(String title, String detail) {
    this(title, detail, List.of(), null);
  }

  public InternalServerException(String title, String detail, Throwable cause) {
    this(title, detail, List.of(), cause);
  }

  public InternalServerException(String title, String detail, List<Map<String, String>> reasons) {
    this(title, detail, reasons, null);
  }

  public InternalServerException(
      String title, String detail, List<Map<String, String>> reasons, Throwable cause) {
    super(HttpStatus.INTERNAL_SERVER_ERROR, title, detail, reasons, cause);
  }
}
