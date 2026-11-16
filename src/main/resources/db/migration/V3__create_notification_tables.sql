-- V3: Create notification table
CREATE TABLE notification (
    notification_id UUID PRIMARY KEY,
    recipient_email VARCHAR(150) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

