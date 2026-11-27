package synapse.bank.user;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.when;

import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;

@ExtendWith(MockitoExtension.class)
class DatabaseUserDetailsServiceTest {

  @Mock private UserRepository users;

  @InjectMocks private DatabaseUserDetailsService service;

  @Test
  void loadsUserDetailsWithRole() {
    when(users.findByUsername("raiyan"))
        .thenReturn(Optional.of(User.register("raiyan", "hash", "pinhash", Role.STAFF)));

    UserDetails details = service.loadUserByUsername("raiyan");

    assertEquals("raiyan", details.getUsername());
    assertEquals("hash", details.getPassword());
    assertTrue(details.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF")));
  }

  @Test
  void throwsWhenUserMissing() {
    when(users.findByUsername("ghost")).thenReturn(Optional.empty());

    assertThrows(UsernameNotFoundException.class, () -> service.loadUserByUsername("ghost"));
  }
}
