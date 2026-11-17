
ALTER TABLE app_user DROP CONSTRAINT ck_app_user_role;
ALTER TABLE app_user ADD CONSTRAINT ck_app_user_role
    CHECK (role IN ('SUPER_ADMIN','MANUFACTURING_ADMIN','WAREHOUSE_ADMIN',
                    'WAREHOUSE_SUPERVISOR','AGENCY_MANAGER','AGENT'));


CREATE TABLE super_admin (
    user_id  UUID        NOT NULL,
    role     VARCHAR(30) NOT NULL DEFAULT 'SUPER_ADMIN',

    CONSTRAINT pk_super_admin      PRIMARY KEY (user_id),
    CONSTRAINT ck_super_admin_role CHECK (role = 'SUPER_ADMIN'),
    CONSTRAINT fk_super_admin_user FOREIGN KEY (user_id, role)
        REFERENCES app_user (user_id, role) ON DELETE CASCADE
);


CREATE UNIQUE INDEX uq_app_user_one_active_super_admin
    ON app_user (role)
    WHERE role = 'SUPER_ADMIN' AND account_status = 'ACTIVE';


ALTER TABLE manufacturing_admin
    ADD COLUMN created_by UUID NOT NULL,
    ADD CONSTRAINT fk_manufacturing_admin_created_by
        FOREIGN KEY (created_by) REFERENCES super_admin (user_id);

CREATE INDEX idx_manufacturing_admin_created_by ON manufacturing_admin (created_by);
