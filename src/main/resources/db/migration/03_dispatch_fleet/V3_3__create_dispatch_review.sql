
CREATE TABLE dispatch_review (
    review_id               UUID         NOT NULL DEFAULT gen_random_uuid(),
    dispatch_allocation_id  UUID         NOT NULL,
    reviewed_by             UUID         NOT NULL,
    outcome                 VARCHAR(20)  NOT NULL,
    comments                TEXT,
    reviewed_at             TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT pk_dispatch_review            PRIMARY KEY (review_id),
    CONSTRAINT fk_dispatch_review_allocation FOREIGN KEY (dispatch_allocation_id)
        REFERENCES dispatch_allocation (dispatch_allocation_id) ON DELETE CASCADE,
    CONSTRAINT fk_dispatch_review_manager    FOREIGN KEY (reviewed_by) REFERENCES agency_manager (user_id),
    CONSTRAINT ck_dispatch_review_outcome    CHECK (outcome IN ('ACCEPTED','REJECTED','CHANGE_REQUESTED')),
    CONSTRAINT ck_dispatch_review_comment    CHECK (outcome = 'ACCEPTED' OR comments IS NOT NULL)
);
CREATE INDEX idx_dispatch_review_allocation ON dispatch_review (dispatch_allocation_id);
