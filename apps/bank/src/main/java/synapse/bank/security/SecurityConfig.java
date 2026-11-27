package synapse.bank.security;

import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import synapse.bank.user.DatabaseUserDetailsService;
import tools.jackson.databind.json.JsonMapper;
import synapse.common.api.ApiError;
import synapse.common.api.ApiMetaFactory;
import synapse.common.api.ApiResponse;

@Configuration
public class SecurityConfig {

  @Bean
  SecurityFilterChain securityFilterChain(
      HttpSecurity http,
      ApiMetaFactory metaFactory,
      JsonMapper jsonMapper
  ) throws Exception {
    return http
        .csrf(csrf -> csrf.disable())
        .authorizeHttpRequests(
            auth ->
                auth
                    .requestMatchers(HttpMethod.POST, "/api/users")
                    .permitAll()
                    .requestMatchers("/docs", "/v3/api-docs", "/v3/api-docs/**")
                    .permitAll()
                    .anyRequest()
                    .authenticated())
        .httpBasic(Customizer.withDefaults())
        .exceptionHandling(
            e ->
                e.authenticationEntryPoint(
                        (req, res, ex) ->
                            writeError(
                                res, metaFactory, jsonMapper, HttpStatus.FORBIDDEN,
                                "Forbidden", "Authentication is required"))
                    .accessDeniedHandler(
                        (req, res, ex) ->
                            writeError(
                                res, metaFactory, jsonMapper, HttpStatus.FORBIDDEN,
                                "Forbidden", "Access is denied")))
        .build();
  }

  @Bean
  PasswordEncoder passwordEncoder() {
    return new BCryptPasswordEncoder();
  }

  @Bean
  DaoAuthenticationProvider daoAuthenticationProvider(
      DatabaseUserDetailsService userDetailsService,
      PasswordEncoder passwordEncoder
  ) {
    DaoAuthenticationProvider provider = new DaoAuthenticationProvider(userDetailsService);
    provider.setPasswordEncoder(passwordEncoder);
    return provider;
  }

  private static void writeError(
      HttpServletResponse response,
      ApiMetaFactory metaFactory,
      JsonMapper jsonMapper,
      HttpStatus status,
      String title,
      String detail
  ) throws IOException {
    response.setStatus(status.value());
    response.setContentType(MediaType.APPLICATION_JSON_VALUE);
    jsonMapper.writeValue(
        response.getWriter(),
        ApiResponse.fail(
            ApiError.builder().title(title).detail(detail).build(), metaFactory.current()));
  }
}
