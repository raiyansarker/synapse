package synapse.bank.security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import synapse.bank.user.DatabaseUserDetailsService;

@Configuration
public class SecurityConfig {

  @Bean
  SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
    return http
        .csrf(csrf -> csrf.disable())
        .authorizeHttpRequests(
            auth ->
                auth
                    .requestMatchers(HttpMethod.POST, "/api/users")
                    .permitAll()
                    .requestMatchers(
                        HttpMethod.POST,
                        "/api/accounts/*/freeze",
                        "/api/accounts/*/unfreeze",
                        "/api/accounts/*/close")
                    .hasRole("STAFF")
                    .anyRequest()
                    .authenticated())
        .httpBasic(Customizer.withDefaults())
        .formLogin(Customizer.withDefaults())
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
}
