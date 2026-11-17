
CREATE TABLE warehouse (
    warehouse_id    UUID          NOT NULL DEFAULT gen_random_uuid(),
    warehouse_code  VARCHAR(20)   NOT NULL,
    warehouse_name  VARCHAR(150)  NOT NULL,
    address         TEXT          NOT NULL,
    contact_number  VARCHAR(20),
    latitude        NUMERIC(9,6),
    longitude       NUMERIC(9,6),
    is_active       BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),

    CONSTRAINT pk_warehouse       PRIMARY KEY (warehouse_id),
    CONSTRAINT uq_warehouse_code  UNIQUE (warehouse_code),
    CONSTRAINT ck_warehouse_lat   CHECK (latitude  BETWEEN  -90 AND  90),
    CONSTRAINT ck_warehouse_lng   CHECK (longitude BETWEEN -180 AND 180),
    CONSTRAINT ck_warehouse_latlng_pair CHECK ((latitude IS NULL) = (longitude IS NULL))
);
