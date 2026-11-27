package synapse.bank.user.controller;

import jakarta.validation.Valid;
import java.io.IOException;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
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

  @GetMapping("/{id}")
  public UserResponse get(
      @PathVariable
      String id
  ) {
    return this.userService.getUser(id);
  }

  @PutMapping("/{id}/avatar")
  public UserResponse updateAvatar(
      @PathVariable
      String id,
      @RequestParam("file")
      MultipartFile file
  ) throws IOException {
    return this.userService.updateAvatar(id, file.getBytes());
  }

  @GetMapping(value = "/{id}/avatar", produces = MediaType.APPLICATION_OCTET_STREAM_VALUE)
  public byte[] getAvatar(
      @PathVariable
      String id
  ) {
    return this.userService.getAvatar(id);
  }
}
