
CREATE TABLE complaint (
    complaint_id     UUID         NOT NULL DEFAULT gen_random_uuid(),
    agency_id        UUID         NOT NULL,
    outlet_id        UUID,
    trip_id          UUID,
    raised_by        UUID         NOT NULL,
    complaint_type   VARCHAR(30)  NOT NULL,
    description      TEXT         NOT NULL,
    status           VARCHAR(20)  NOT NULL DEFAULT 'OPEN',
    resolution_note  TEXT,
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    resolved_at      TIMESTAMPTZ,

    CONSTRAINT pk_complaint          PRIMARY KEY (complaint_id),
    CONSTRAINT fk_complaint_agency   FOREIGN KEY (agency_id) REFERENCES agency (agency_id),
    CONSTRAINT fk_complaint_outlet   FOREIGN KEY (outlet_id) REFERENCES retail_outlet (outlet_id),
    CONSTRAINT fk_complaint_trip     FOREIGN KEY (trip_id)   REFERENCES delivery_trip (trip_id),
    CONSTRAINT fk_complaint_user     FOREIGN KEY (raised_by) REFERENCES app_user (user_id),
    CONSTRAINT ck_complaint_type     CHECK (complaint_type IN ('LATE_DELIVERY','SHORT_DELIVERY','DAMAGED_GOODS',
                                                               'WRONG_ITEM','STAFF_BEHAVIOUR','OTHER')),
    CONSTRAINT ck_complaint_status   CHECK (status IN ('OPEN','IN_PROGRESS','RESOLVED','CLOSED')),
    CONSTRAINT ck_complaint_resolved CHECK (status NOT IN ('RESOLVED','CLOSED') OR resolved_at IS NOT NULL)
);
CREATE INDEX idx_complaint_agency ON complaint (agency_id, created_at);
CREATE INDEX idx_complaint_outlet ON complaint (outlet_id);

CREATE TABLE agency_feedback (
    feedback_id     UUID         NOT NULL DEFAULT gen_random_uuid(),
    agency_id       UUID         NOT NULL,
    submitted_by    UUID         NOT NULL,
    rating          SMALLINT,
    feedback_text   TEXT         NOT NULL,
    admin_response  TEXT,
    responded_by    UUID,
    status          VARCHAR(20)  NOT NULL DEFAULT 'PENDING',
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    responded_at    TIMESTAMPTZ,

    CONSTRAINT pk_agency_feedback           PRIMARY KEY (feedback_id),
    CONSTRAINT fk_agency_feedback_agency    FOREIGN KEY (agency_id)    REFERENCES agency (agency_id),
    CONSTRAINT fk_agency_feedback_manager   FOREIGN KEY (submitted_by) REFERENCES agency_manager (user_id),
    CONSTRAINT fk_agency_feedback_admin     FOREIGN KEY (responded_by) REFERENCES manufacturing_admin (user_id),
    CONSTRAINT ck_agency_feedback_rating    CHECK (rating IS NULL OR rating BETWEEN 1 AND 5),
    CONSTRAINT ck_agency_feedback_status    CHECK (status IN ('PENDING','REVIEWED','RESPONDED')),
    CONSTRAINT ck_agency_feedback_responded CHECK (status <> 'RESPONDED'
                                                   OR (admin_response IS NOT NULL AND responded_by IS NOT NULL))
);
CREATE INDEX idx_agency_feedback_agency ON agency_feedback (agency_id);
