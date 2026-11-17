package com.nexus.dms.service;

import com.nexus.dms.entity.Notification;
import com.nexus.dms.repository.NotificationRepository;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
public class NotificationService {

    private final NotificationRepository repository;

    public NotificationService(NotificationRepository repository) {
        this.repository = repository;
    }

    public List<Notification> listNotifications(UUID userId) {
        if (userId != null) {
            return repository.findByUserIdOrderByCreatedAtDesc(userId);
        }
        return repository.findAll();
    }

    public Notification sendNotification(Notification payload) {
        return repository.save(payload);
    }

    public Notification markRead(UUID notificationId) {
        Notification item = repository.findById(notificationId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "No notification with id: " + notificationId));
        item.setIsRead(true);
        item.setReadAt(OffsetDateTime.now());
        return repository.save(item);
    }
}
