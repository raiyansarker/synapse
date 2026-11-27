package synapse.bank.notification;

import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import synapse.bank.notification.dto.NotificationResponse;
import synapse.bank.user.User;
import synapse.bank.user.UserRepository;
import synapse.common.exception.NotFoundException;

@Service
@RequiredArgsConstructor
public class NotificationService {
  private final NotificationRepository notifications;
  private final UserRepository users;

  @Transactional
  public Notification notify(String userId, String title, String message) {
    return this.notifications.save(Notification.of(findUser(userId), title, message));
  }

  @Transactional(readOnly = true)
  public List<NotificationResponse> list(String userId) {
    User user = findUser(userId);
    return this.notifications.findByUserIdOrderByCreatedAtDesc(user.getId()).stream()
        .map(NotificationService::toResponse)
        .toList();
  }

  @Transactional
  public void markRead(String userId, String notificationId) {
    User user = findUser(userId);
    Notification notification =
        this.notifications
            .findById(notificationId)
            .orElseThrow(
                () ->
                    new NotFoundException(
                        "Notification not found", "No notification exists with id " + notificationId));
    if (!notification.getUser().getId().equals(user.getId())) {
      throw new NotFoundException(
          "Notification not found", "No notification exists with id " + notificationId);
    }
    notification.markRead();
    this.notifications.save(notification);
  }

  private User findUser(String userId) {
    return this.users
        .findById(userId)
        .orElseThrow(() -> new NotFoundException("User not found", "No user exists with id " + userId));
  }

  private static NotificationResponse toResponse(Notification notification) {
    return new NotificationResponse(
        notification.getId(),
        notification.getTitle(),
        notification.getMessage(),
        notification.isRead(),
        notification.getCreatedAt());
  }
}
