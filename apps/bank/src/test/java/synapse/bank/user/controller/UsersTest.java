package synapse.bank.user.controller;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.ImportAutoConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import synapse.bank.user.Role;
import synapse.bank.user.UserService;
import synapse.bank.user.dto.UserResponse;
import synapse.common.CommonHttpAutoConfiguration;
import synapse.common.exception.ConflictException;

@WebMvcTest(Users.class)
@ImportAutoConfiguration(CommonHttpAutoConfiguration.class)
class UsersTest {

  @Autowired private MockMvc mvc;

  @MockitoBean private UserService userService;

  @Test
  void registerReturnsCreatedUser() throws Exception {
    when(userService.register(any())).thenReturn(new UserResponse("id-1", "raiyan", Role.CUSTOMER));

    mvc.perform(
            post("/api/users")
                .contentType(MediaType.APPLICATION_JSON)
                .header("X-Request-Id", "req-1")
                .content(
                    """
                    {"username":"raiyan","password":"secret123","pin":"1234"}
                    """
                ))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.success").value(true))
        .andExpect(jsonPath("$.data.id").value("id-1"))
        .andExpect(jsonPath("$.data.username").value("raiyan"))
        .andExpect(jsonPath("$.data.role").value("CUSTOMER"))
        .andExpect(jsonPath("$.error").doesNotExist())
        .andExpect(jsonPath("$.meta.requestId").value("req-1"));
  }

  @Test
  void registerReturnsConflictWhenUsernameTaken() throws Exception {
    when(userService.register(any()))
        .thenThrow(new ConflictException("User already exists", "The username raiyan is taken."));

    mvc.perform(
            post("/api/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content(
                    """
                    {"username":"raiyan","password":"secret123","pin":"1234"}
                    """
                ))
        .andExpect(status().isConflict())
        .andExpect(jsonPath("$.success").value(false))
        .andExpect(jsonPath("$.data").doesNotExist())
        .andExpect(jsonPath("$.error.title").value("User already exists"));
  }

  @Test
  void registerRejectsInvalidPin() throws Exception {
    mvc.perform(
            post("/api/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content(
                    """
                    {"username":"raiyan","password":"secret123","pin":"12ab"}
                    """
                ))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.success").value(false))
        .andExpect(jsonPath("$.error.title").value("Bad Request"));
  }
}
