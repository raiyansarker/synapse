package synapse.bank.common.exception;

import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;

public class BadRequestException extends HttpError {

  public BadRequestException(String detail) {
    this(detail, List.of());
  }

  public BadRequestException(String detail, List<Map<String, String>> reasons) {
    super(HttpStatus.BAD_REQUEST, "Bad Request", detail, reasons);
  }
}
