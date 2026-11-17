
CREATE TABLE audit_log (
    log_id       BIGINT       GENERATED ALWAYS AS IDENTITY,
    user_id      UUID,
    action       VARCHAR(50)  NOT NULL,   -- e.g. CREATE, UPDATE, APPROVE, LOGIN
    entity_type  VARCHAR(50)  NOT NULL,   -- e.g. SAP_REPORT, DISPATCH_SCHEDULE
    entity_id    UUID,
    details      JSONB,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT pk_audit_log      PRIMARY KEY (log_id),
    CONSTRAINT fk_audit_log_user FOREIGN KEY (user_id)
        REFERENCES app_user (user_id) ON DELETE SET NULL
);
CREATE INDEX idx_audit_log_entity ON audit_log (entity_type, entity_id);
CREATE INDEX idx_audit_log_user   ON audit_log (user_id, created_at);
