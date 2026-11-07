package synapse.common.exception;

import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;

public class UnprocessableEntityException extends HttpError {

  public UnprocessableEntityException(String title, String detail) {
    this(title, detail, List.of());
  }

  public UnprocessableEntityException(
      String title, String detail, List<Map<String, String>> reasons) {
    super(HttpStatus.UNPROCESSABLE_ENTITY, title, detail, reasons);
  }
}
