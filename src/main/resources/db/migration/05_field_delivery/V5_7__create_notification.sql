
CREATE TABLE notification (
    notification_id    UUID          NOT NULL DEFAULT gen_random_uuid(),
    user_id            UUID          NOT NULL,
    notification_type  VARCHAR(30)   NOT NULL,
    title              VARCHAR(150)  NOT NULL,
    message            TEXT          NOT NULL,
    reference_type     VARCHAR(30),
    reference_id       UUID,
    is_read            BOOLEAN       NOT NULL DEFAULT FALSE,
    created_at         TIMESTAMPTZ   NOT NULL DEFAULT now(),
    read_at            TIMESTAMPTZ,

    CONSTRAINT pk_notification       PRIMARY KEY (notification_id),
    CONSTRAINT fk_notification_user  FOREIGN KEY (user_id) REFERENCES app_user (user_id) ON DELETE CASCADE,
    CONSTRAINT ck_notification_type  CHECK (notification_type IN ('LOW_STOCK','ORDER_UPDATE','DISPATCH_SCHEDULED',
                                                                  'TRIP_ASSIGNED','DISCREPANCY','COMPLAINT',
                                                                  'PROPOSAL_REVIEWED','SYSTEM')),
    CONSTRAINT ck_notification_ref   CHECK ((reference_type IS NULL) = (reference_id IS NULL)),
    CONSTRAINT ck_notification_read  CHECK (is_read = (read_at IS NOT NULL))
);
-- fast "my unread notifications" query
CREATE INDEX idx_notification_user_unread ON notification (user_id, created_at) WHERE is_read = FALSE;
