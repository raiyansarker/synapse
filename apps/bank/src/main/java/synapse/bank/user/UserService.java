package synapse.bank.user;

import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import synapse.bank.account.Account;
import synapse.bank.account.AccountRepository;
import synapse.bank.account.dto.AccountResponse;
import synapse.bank.user.dto.RegisterRequest;
import synapse.bank.user.dto.UserResponse;
import synapse.common.exception.BadRequestException;
import synapse.common.exception.ConflictException;
import synapse.common.exception.NotFoundException;

@Service
@RequiredArgsConstructor
public class UserService {
  private static final int MAX_AVATAR_BYTES = 2 * 1024 * 1024;

  private final UserRepository users;
  private final AccountRepository accounts;
  private final PasswordEncoder passwordEncoder;

  @Transactional
  public UserResponse register(RegisterRequest request) {
    if (this.users.existsByUsername(request.username())) {
      throw new ConflictException(
          "User already exists",
          "The username " + request.username() + " is taken. Choose another one.");
    }
    User user =
        User.register(request.username(), this.passwordEncoder.encode(request.pin()));
    Account account = Account.open(request.username());
    user.assignAccount(account);
    this.accounts.save(account);
    this.users.save(user);
    return toResponse(user);
  }

  @Transactional(readOnly = true)
  public UserResponse getUser(String id) {
    return toResponse(findUser(id));
  }

  @Transactional
  public UserResponse updateAvatar(String id, byte[] avatar) {
    if (avatar == null || avatar.length == 0) {
      throw new BadRequestException("Avatar required", "Upload a non-empty image file.");
    }
    if (avatar.length > MAX_AVATAR_BYTES) {
      throw new BadRequestException("Avatar too large", "Avatar must be at most 2 MB.");
    }
    User user = findUser(id);
    user.updateAvatar(avatar);
    this.users.save(user);
    return toResponse(user);
  }

  public byte[] getAvatar(String id) {
    User user = findUser(id);
    if (user.getAvatar() == null) {
      throw new NotFoundException("Avatar not found", "User " + user.getUsername() + " has no avatar.");
    }
    return user.getAvatar();
  }

  private User findUser(String id) {
    return this.users
        .findById(id)
        .orElseThrow(() -> new NotFoundException("User not found", "No user exists with id " + id));
  }

  private static UserResponse toResponse(User user) {
    Account account = user.getAccount();
    AccountResponse accountResponse =
        account == null
            ? null
            : new AccountResponse(
                account.getVirtualAddress(), account.getBalance(), account.getStatus());
    return new UserResponse(user.getId(), user.getUsername(), user.getRole(), accountResponse);
  }
}
