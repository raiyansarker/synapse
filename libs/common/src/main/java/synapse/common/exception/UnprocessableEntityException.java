package synapse.common.exception;

import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;

public class UnprocessableEntityException extends HttpError {

  public UnprocessableEntityException(String detail) {
    this(detail, List.of());
  }

  public UnprocessableEntityException(String detail, List<Map<String, String>> reasons) {
    super(HttpStatus.UNPROCESSABLE_ENTITY, "Unprocessable Entity", detail, reasons);
  }
}
