package synapse.bank.notification.dto;

import java.time.Instant;

public record NotificationResponse(
    String id,
    String title,
    String message,
    boolean read,
    Instant createdAt
) {}
