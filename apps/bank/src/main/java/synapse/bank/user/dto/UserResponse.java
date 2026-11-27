package synapse.bank.user.dto;

import synapse.bank.user.Role;

public record UserResponse(String id, String username, Role role) {}
