package synapse.bank.common.exception;

import java.util.List;
import java.util.Map;
import lombok.Getter;
import org.springframework.http.HttpStatus;

@Getter
public abstract class HttpError extends RuntimeException {

  private final HttpStatus status;
  private final String title;
  private final String detail;
  private final List<Map<String, String>> reasons;

  protected HttpError(
      HttpStatus status,
      String title,
      String detail,
      List<Map<String, String>> reasons
  ) {
    super(detail);
    this.status = status;
    this.title = title;
    this.detail = detail;
    this.reasons = reasons == null ? List.of() : List.copyOf(reasons);
  }

  protected HttpError(
      HttpStatus status,
      String title,
      String detail,
      List<Map<String, String>> reasons,
      Throwable cause
  ) {
    super(detail, cause);
    this.status = status;
    this.title = title;
    this.detail = detail;
    this.reasons = reasons == null ? List.of() : List.copyOf(reasons);
  }
}
