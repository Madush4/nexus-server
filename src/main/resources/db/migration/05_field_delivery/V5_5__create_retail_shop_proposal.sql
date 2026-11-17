
CREATE TABLE retail_shop_proposal (
    proposal_id         UUID          NOT NULL DEFAULT gen_random_uuid(),
    proposed_by         UUID          NOT NULL,
    area_id             UUID          NOT NULL,
    shop_name           VARCHAR(150)  NOT NULL,
    shop_type           VARCHAR(30)   NOT NULL,
    owner_name          VARCHAR(150),
    contact_number      VARCHAR(20)   NOT NULL,
    address             TEXT          NOT NULL,
    latitude            NUMERIC(9,6),
    longitude           NUMERIC(9,6),
    status              VARCHAR(20)   NOT NULL DEFAULT 'PENDING',
    reviewed_by         UUID,
    review_note         TEXT,
    created_outlet_id   UUID,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    reviewed_at         TIMESTAMPTZ,

    CONSTRAINT pk_retail_shop_proposal          PRIMARY KEY (proposal_id),
    CONSTRAINT fk_retail_shop_proposal_agent    FOREIGN KEY (proposed_by)       REFERENCES agent (user_id),
    CONSTRAINT fk_retail_shop_proposal_area     FOREIGN KEY (area_id)           REFERENCES operational_area (area_id),
    CONSTRAINT fk_retail_shop_proposal_manager  FOREIGN KEY (reviewed_by)       REFERENCES agency_manager (user_id),
    CONSTRAINT fk_retail_shop_proposal_outlet   FOREIGN KEY (created_outlet_id) REFERENCES retail_outlet (outlet_id),
    CONSTRAINT uq_retail_shop_proposal_outlet   UNIQUE (created_outlet_id),
    CONSTRAINT ck_retail_shop_proposal_type     CHECK (shop_type IN ('GROCERY','SUPERMARKET','PHARMACY',
                                                                     'BAKERY','OTHER')),
    CONSTRAINT ck_retail_shop_proposal_status   CHECK (status IN ('PENDING','APPROVED','REJECTED')),
    CONSTRAINT ck_retail_shop_proposal_lat      CHECK (latitude  BETWEEN  -90 AND  90),
    CONSTRAINT ck_retail_shop_proposal_lng      CHECK (longitude BETWEEN -180 AND 180),
    CONSTRAINT ck_retail_shop_proposal_pair     CHECK ((latitude IS NULL) = (longitude IS NULL)),
    CONSTRAINT ck_retail_shop_proposal_review   CHECK (status = 'PENDING'
                                                       OR (reviewed_by IS NOT NULL AND reviewed_at IS NOT NULL)),
    CONSTRAINT ck_retail_shop_proposal_approved CHECK (status <> 'APPROVED' OR created_outlet_id IS NOT NULL)
);
CREATE INDEX idx_retail_shop_proposal_area   ON retail_shop_proposal (area_id);
CREATE INDEX idx_retail_shop_proposal_status ON retail_shop_proposal (status);
