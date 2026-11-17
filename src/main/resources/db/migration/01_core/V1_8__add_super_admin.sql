-- =====================================================================
-- V1_8  SUPER_ADMIN role
-- Owner : core (auth & access)
--
-- Business rule: the super admin is the top of the hierarchy.
--   SUPER_ADMIN        -> adds / deactivates MANUFACTURING_ADMIN only
--   MANUFACTURING_ADMIN-> adds / deactivates warehouses, agencies,
--                         WAREHOUSE_ADMIN, AGENCY_MANAGER
--
-- The super admin is NOT created through the website. Seed it once at
-- start-up from environment variables (never put a password hash in a
-- migration file - it would live in Git forever).
-- =====================================================================

-- 1. allow the new role value
ALTER TABLE app_user DROP CONSTRAINT ck_app_user_role;
ALTER TABLE app_user ADD CONSTRAINT ck_app_user_role
    CHECK (role IN ('SUPER_ADMIN','MANUFACTURING_ADMIN','WAREHOUSE_ADMIN',
                    'WAREHOUSE_SUPERVISOR','AGENCY_MANAGER','AGENT'));

-- 2. subclass table, same pattern as the other roles (keeps the EER
--    specialization total: every user has exactly one subclass row)
CREATE TABLE super_admin (
    user_id  UUID        NOT NULL,
    role     VARCHAR(30) NOT NULL DEFAULT 'SUPER_ADMIN',

    CONSTRAINT pk_super_admin      PRIMARY KEY (user_id),
    CONSTRAINT ck_super_admin_role CHECK (role = 'SUPER_ADMIN'),
    CONSTRAINT fk_super_admin_user FOREIGN KEY (user_id, role)
        REFERENCES app_user (user_id, role) ON DELETE CASCADE
);

-- 3. only ONE active super admin at a time
--    (an old one must be deactivated before another is activated)
CREATE UNIQUE INDEX uq_app_user_one_active_super_admin
    ON app_user (role)
    WHERE role = 'SUPER_ADMIN' AND account_status = 'ACTIVE';

-- 4. every manufacturing admin is created by a super admin
--    (the DB enforces it: the FK points at super_admin, not app_user)
ALTER TABLE manufacturing_admin
    ADD COLUMN created_by UUID NOT NULL,
    ADD CONSTRAINT fk_manufacturing_admin_created_by
        FOREIGN KEY (created_by) REFERENCES super_admin (user_id);

CREATE INDEX idx_manufacturing_admin_created_by ON manufacturing_admin (created_by);
