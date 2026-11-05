package synapse.common.exception;

import java.util.List;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.resource.NoResourceFoundException;
import synapse.common.api.ApiError;
import synapse.common.api.ApiMetaFactory;
import synapse.common.api.ApiResponse;

@Slf4j
@RestControllerAdvice
@RequiredArgsConstructor
public class HttpExceptionHandler {

  private final ApiMetaFactory metaFactory;

  @ExceptionHandler(Exception.class)
  public ResponseEntity<ApiResponse<Void>> handle(Exception exception) {
    if (exception instanceof HttpError httpError) {
      return build(httpError.getStatus(), httpError.getTitle(), httpError.getDetail(), httpError.getReasons());
    }

    if (exception instanceof MethodArgumentNotValidException validationException) {
      List<Map<String, String>> reasons = validationException.getBindingResult()
          .getFieldErrors()
          .stream()
          .map(error -> Map.of(
              "field", error.getField(),
              "message", error.getDefaultMessage() == null ? "invalid" : error.getDefaultMessage()
          ))
          .toList();
      return build(HttpStatus.BAD_REQUEST, "Bad Request", "Validation failed", reasons);
    }

    if (exception instanceof MissingServletRequestParameterException missingParameter) {
      return build(
          HttpStatus.BAD_REQUEST,
          "Bad Request",
          "Missing required parameter: " + missingParameter.getParameterName(),
          List.of(Map.of("parameter", missingParameter.getParameterName()))
      );
    }

    if (exception instanceof HttpMessageNotReadableException) {
      return build(HttpStatus.BAD_REQUEST, "Bad Request", "Malformed request body", List.of());
    }

    if (exception instanceof HttpRequestMethodNotSupportedException methodNotSupported) {
      return build(
          HttpStatus.METHOD_NOT_ALLOWED,
          "Method Not Allowed",
          methodNotSupported.getMessage(),
          List.of()
      );
    }

    if (exception instanceof NoResourceFoundException) {
      return build(HttpStatus.NOT_FOUND, "Not Found", "Resource not found", List.of());
    }

    log.error("Unhandled exception", exception);
    return build(
        HttpStatus.INTERNAL_SERVER_ERROR,
        "Internal Server Error",
        "An unexpected error occurred",
        List.of()
    );
  }

  private ResponseEntity<ApiResponse<Void>> build(
      HttpStatus status,
      String title,
      String detail,
      List<Map<String, String>> reasons
  ) {
    ApiError error = ApiError.builder()
        .title(title)
        .detail(detail)
        .reasons(reasons)
        .build();

    return ResponseEntity.status(status).body(ApiResponse.fail(error, metaFactory.current()));
  }
}
