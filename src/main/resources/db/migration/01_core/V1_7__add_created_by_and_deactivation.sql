-- =====================================================================
-- V1_7  Who created / deactivated warehouses, agencies and users
-- Owner : core (auth & access)
--
-- Business rule: the manufacturing admin adds and removes warehouses,
-- agencies and their admins (warehouse_admin, agency_manager).
--
-- "Remove" = DEACTIVATE (soft delete), never DELETE:
--   * old dispatches, trips, reports still point at these rows (FKs)
--   * history and audit must survive
-- Hard DELETE is still blocked by the existing FKs, which is intended.
-- =====================================================================

-- ---------- warehouse ----------
ALTER TABLE warehouse
    ADD COLUMN created_by      UUID,
    ADD COLUMN updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    ADD COLUMN deactivated_at  TIMESTAMPTZ,
    ADD COLUMN deactivated_by  UUID,
    ADD CONSTRAINT fk_warehouse_created_by     FOREIGN KEY (created_by)     REFERENCES manufacturing_admin (user_id),
    ADD CONSTRAINT fk_warehouse_deactivated_by FOREIGN KEY (deactivated_by) REFERENCES manufacturing_admin (user_id),
    -- inactive <=> deactivation recorded
    ADD CONSTRAINT ck_warehouse_deactivation   CHECK (is_active = (deactivated_at IS NULL)
                                                      AND (deactivated_at IS NULL) = (deactivated_by IS NULL));

CREATE TRIGGER trg_warehouse_updated_at BEFORE UPDATE ON warehouse
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ---------- agency ----------
ALTER TABLE agency
    ADD COLUMN created_by      UUID,
    ADD COLUMN deactivated_at  TIMESTAMPTZ,
    ADD COLUMN deactivated_by  UUID,
    ADD CONSTRAINT fk_agency_created_by     FOREIGN KEY (created_by)     REFERENCES manufacturing_admin (user_id),
    ADD CONSTRAINT fk_agency_deactivated_by FOREIGN KEY (deactivated_by) REFERENCES manufacturing_admin (user_id),
    ADD CONSTRAINT ck_agency_deactivation   CHECK (is_active = (deactivated_at IS NULL)
                                                   AND (deactivated_at IS NULL) = (deactivated_by IS NULL));

-- ---------- app_user ----------
-- created_by: who registered this account (self-reference).
--   manufacturing admin -> warehouse_admin, agency_manager
--   (warehouse admin -> supervisors, agency manager -> agents, if you allow it)
-- NULL only for the first seeded manufacturing admin.
-- Removing a user = account_status 'INACTIVE' + deactivated_at/by.
ALTER TABLE app_user
    ADD COLUMN created_by      UUID,
    ADD COLUMN deactivated_at  TIMESTAMPTZ,
    ADD COLUMN deactivated_by  UUID,
    ADD CONSTRAINT fk_app_user_created_by     FOREIGN KEY (created_by)     REFERENCES app_user (user_id),
    ADD CONSTRAINT fk_app_user_deactivated_by FOREIGN KEY (deactivated_by) REFERENCES app_user (user_id),
    ADD CONSTRAINT ck_app_user_not_self_created CHECK (created_by IS NULL OR created_by <> user_id),
    ADD CONSTRAINT ck_app_user_deactivation   CHECK ((account_status = 'INACTIVE') = (deactivated_at IS NOT NULL)
                                                     AND (deactivated_at IS NULL) = (deactivated_by IS NULL));

CREATE INDEX idx_app_user_created_by ON app_user (created_by);
CREATE INDEX idx_app_user_role_status ON app_user (role, account_status);
