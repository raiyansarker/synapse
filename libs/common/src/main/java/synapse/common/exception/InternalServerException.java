package synapse.common.exception;

import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;

public class InternalServerException extends HttpError {

  public InternalServerException(String detail) {
    this(detail, List.of(), null);
  }

  public InternalServerException(String detail, Throwable cause) {
    this(detail, List.of(), cause);
  }

  public InternalServerException(String detail, List<Map<String, String>> reasons) {
    this(detail, reasons, null);
  }

  public InternalServerException(
      String detail, List<Map<String, String>> reasons, Throwable cause) {
    super(HttpStatus.INTERNAL_SERVER_ERROR, "Internal Server Error", detail, reasons, cause);
  }
}
