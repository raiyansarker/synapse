package synapse.bank.common.api;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Value;

@Value
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ApiResponse<T> {

  boolean success;
  T data;
  ApiError error;
  ApiMeta meta;

  public static <T> ApiResponse<T> ok(T data, ApiMeta meta) {
    return new ApiResponse<>(true, data, null, meta);
  }

  public static <T> ApiResponse<T> fail(ApiError error, ApiMeta meta) {
    return new ApiResponse<>(false, null, error, meta);
  }
}
