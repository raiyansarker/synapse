package synapse.bank.user.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record RegisterRequest(
    @NotBlank
    @Pattern(regexp = "[a-z0-9]+", message = "username must be [a-z0-9]+")
    String username,

    @NotBlank
    String password,

    @NotBlank
    @Pattern(regexp = "[0-9]{4,6}", message = "pin must be 4-6 digits")
    String pin
) {}
