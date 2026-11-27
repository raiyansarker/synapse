package synapse.bank.user.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import synapse.bank.user.UserService;
import synapse.bank.user.dto.RegisterRequest;
import synapse.bank.user.dto.UserResponse;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class Users {

  private final UserService userService;

  @PostMapping
  public UserResponse register(
      @Valid
      @RequestBody
      RegisterRequest request
  ) {
    return this.userService.register(request);
  }
}
