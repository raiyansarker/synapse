package synapse.bank.user;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;
import synapse.bank.account.AccountRepository;
import synapse.bank.user.dto.RegisterRequest;
import synapse.bank.user.dto.UserResponse;
import synapse.common.exception.ConflictException;

@ExtendWith(MockitoExtension.class)
class UserServiceTest {

  @Mock private UserRepository users;
  @Mock private AccountRepository accounts;
  @Mock private PasswordEncoder passwordEncoder;

  @InjectMocks private UserService service;

  @Test
  void registerEncodesCredentialsAndSavesUserWithAccount() {
    when(users.existsByUsername("raiyan")).thenReturn(false);
    when(passwordEncoder.encode(anyString())).thenReturn("encoded");

    UserResponse response =
        service.register(new RegisterRequest("raiyan", "secret123", "1234"));

    assertEquals("raiyan", response.username());
    assertEquals(Role.CUSTOMER, response.role());
    verify(passwordEncoder).encode("secret123");
    verify(passwordEncoder).encode("1234");
    verify(accounts).save(any());
    verify(users).save(any());
  }

  @Test
  void registerRejectsTakenUsername() {
    when(users.existsByUsername("raiyan")).thenReturn(true);

    assertThrows(
        ConflictException.class,
        () -> service.register(new RegisterRequest("raiyan", "secret123", "1234")));
    verify(users, never()).save(any());
    verify(accounts, never()).save(any());
  }
}
