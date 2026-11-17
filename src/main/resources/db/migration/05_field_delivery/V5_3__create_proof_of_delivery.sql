
CREATE TABLE proof_of_delivery (
    pod_id         UUID          NOT NULL DEFAULT gen_random_uuid(),
    trip_stop_id   UUID          NOT NULL,
    captured_by    UUID          NOT NULL,
    receiver_name  VARCHAR(150)  NOT NULL,
    signature_url  TEXT          NOT NULL,
    photo_url      TEXT,
    latitude       NUMERIC(9,6),
    longitude      NUMERIC(9,6),
    delivered_at   TIMESTAMPTZ   NOT NULL DEFAULT now(),
    remarks        TEXT,

    CONSTRAINT pk_proof_of_delivery        PRIMARY KEY (pod_id),
    CONSTRAINT fk_proof_of_delivery_stop   FOREIGN KEY (trip_stop_id) REFERENCES trip_stop (trip_stop_id),
    CONSTRAINT fk_proof_of_delivery_agent  FOREIGN KEY (captured_by)  REFERENCES agent (user_id),
    CONSTRAINT uq_proof_of_delivery_stop   UNIQUE (trip_stop_id),
    CONSTRAINT ck_proof_of_delivery_lat    CHECK (latitude  BETWEEN  -90 AND  90),
    CONSTRAINT ck_proof_of_delivery_lng    CHECK (longitude BETWEEN -180 AND 180),
    CONSTRAINT ck_proof_of_delivery_pair   CHECK ((latitude IS NULL) = (longitude IS NULL))
);
