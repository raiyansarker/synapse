package synapse.bank.notification.controller;

import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import synapse.bank.notification.NotificationService;
import synapse.bank.notification.dto.NotificationResponse;

@RestController
@RequestMapping("/api/users/{userId}/notifications")
@RequiredArgsConstructor
public class Notifications {

  private final NotificationService notificationService;

  @GetMapping
  public List<NotificationResponse> list(
      @PathVariable
      String userId
  ) {
    return this.notificationService.list(userId);
  }
}
