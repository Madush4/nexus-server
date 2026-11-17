
CREATE TABLE outlet_return (
    return_id          UUID         NOT NULL DEFAULT gen_random_uuid(),
    outlet_id          UUID         NOT NULL,
    recorded_by        UUID         NOT NULL,
    collected_stop_id  UUID,
    reason             TEXT         NOT NULL,
    status             VARCHAR(20)  NOT NULL DEFAULT 'REQUESTED',
    created_at         TIMESTAMPTZ  NOT NULL DEFAULT now(),
    collected_at       TIMESTAMPTZ,

    CONSTRAINT pk_outlet_return         PRIMARY KEY (return_id),
    CONSTRAINT fk_outlet_return_outlet  FOREIGN KEY (outlet_id)   REFERENCES retail_outlet (outlet_id),
    CONSTRAINT fk_outlet_return_agent   FOREIGN KEY (recorded_by) REFERENCES agent (user_id),
    CONSTRAINT fk_outlet_return_stop    FOREIGN KEY (collected_stop_id, outlet_id)
        REFERENCES trip_stop (trip_stop_id, outlet_id),
    CONSTRAINT ck_outlet_return_status  CHECK (status IN ('REQUESTED','COLLECTED','ACCEPTED','REJECTED')),
    CONSTRAINT ck_outlet_return_collect CHECK (status = 'REQUESTED'
                                               OR (collected_stop_id IS NOT NULL AND collected_at IS NOT NULL))
);
CREATE INDEX idx_outlet_return_outlet ON outlet_return (outlet_id);
CREATE INDEX idx_outlet_return_stop   ON outlet_return (collected_stop_id);

CREATE TABLE outlet_return_item (
    return_item_id  UUID         NOT NULL DEFAULT gen_random_uuid(),
    return_id       UUID         NOT NULL,
    product_id      UUID         NOT NULL,
    quantity        INTEGER      NOT NULL,
    item_condition  VARCHAR(20)  NOT NULL,

    CONSTRAINT pk_outlet_return_item          PRIMARY KEY (return_item_id),
    CONSTRAINT fk_outlet_return_item_return   FOREIGN KEY (return_id)
        REFERENCES outlet_return (return_id) ON DELETE CASCADE,
    CONSTRAINT fk_outlet_return_item_product  FOREIGN KEY (product_id) REFERENCES product (product_id),
    CONSTRAINT uq_outlet_return_item_line     UNIQUE (return_id, product_id, item_condition),
    CONSTRAINT ck_outlet_return_item_qty      CHECK (quantity > 0),
    CONSTRAINT ck_outlet_return_item_cond     CHECK (item_condition IN ('EXPIRED','DAMAGED','WRONG_ITEM','OTHER'))
);
CREATE INDEX idx_outlet_return_item_product ON outlet_return_item (product_id);
