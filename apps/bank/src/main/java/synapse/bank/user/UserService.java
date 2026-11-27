package synapse.bank.user;

import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import synapse.bank.account.Account;
import synapse.bank.account.AccountRepository;
import synapse.bank.user.dto.RegisterRequest;
import synapse.bank.user.dto.UserResponse;
import synapse.common.exception.ConflictException;

@Service
@RequiredArgsConstructor
public class UserService {
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
        User.register(
            request.username(),
            this.passwordEncoder.encode(request.password()),
            this.passwordEncoder.encode(request.pin()));
    Account account = Account.open(request.username());
    user.assignAccount(account);
    this.accounts.save(account);
    this.users.save(user);
    return new UserResponse(user.getId(), user.getUsername(), user.getRole());
  }
}
