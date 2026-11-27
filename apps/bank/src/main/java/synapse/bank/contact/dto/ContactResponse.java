package synapse.bank.contact.dto;

import java.time.Instant;

public record ContactResponse(String id, String virtualAddress, Instant createdAt) {}
