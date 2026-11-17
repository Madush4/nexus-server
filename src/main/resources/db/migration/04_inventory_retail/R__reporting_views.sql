


CREATE OR REPLACE VIEW v_manufacturer_stock AS
SELECT p.product_id,
       p.product_code,
       p.product_name,
       mi.quantity_on_hand                         AS total_qty,
       mi.quantity_reserved                        AS reserved_qty,
       mi.quantity_on_hand - mi.quantity_reserved  AS available_qty,
       (mi.quantity_on_hand - mi.quantity_reserved) < mi.minimum_stock_level AS below_minimum
FROM manufacturer_inventory mi
JOIN product p ON p.product_id = mi.product_id;


CREATE OR REPLACE VIEW v_agency_stock_status AS
SELECT a.agency_id,
       a.agency_name,
       p.product_id,
       p.product_name,
       ai.quantity_on_hand,
       ai.quantity_reserved,
       ai.quantity_on_hand - ai.quantity_reserved  AS available_qty,
       ai.reorder_level,
       (ai.quantity_on_hand - ai.quantity_reserved) <= ai.reorder_level AS needs_reorder
FROM agency_inventory ai
JOIN agency  a ON a.agency_id  = ai.agency_id
JOIN product p ON p.product_id = ai.product_id;


CREATE OR REPLACE VIEW v_agency_complaint_summary AS
SELECT a.agency_id,
       a.agency_name,
       COUNT(c.complaint_id)                                          AS total_complaints,
       COUNT(c.complaint_id) FILTER (WHERE c.status IN ('OPEN','IN_PROGRESS')) AS open_complaints,
       MAX(c.created_at)                                              AS last_complaint_at
FROM agency a
LEFT JOIN complaint c ON c.agency_id = a.agency_id
GROUP BY a.agency_id, a.agency_name;
