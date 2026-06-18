DROP TABLE IF EXISTS customers CASCADE;
CREATE TABLE customers (
    customer_id         VARCHAR(12)   NOT NULL,
    customer_name       VARCHAR(100),
    customer_size       VARCHAR(40),
    city                VARCHAR(40),
    signup_date         DATE,
    account_manager     VARCHAR(60),
    industry            VARCHAR(40),
    payment_terms_days  INTEGER,
    PRIMARY KEY (customer_id)
);

DROP TABLE IF EXISTS couriers CASCADE;
CREATE TABLE couriers (
    courier_id        VARCHAR(12)   NOT NULL,
    hire_date         DATE,
    employment_type   VARCHAR(20),
    city              VARCHAR(40),
    shift_pattern     VARCHAR(20),
    PRIMARY KEY (courier_id)
);

DROP TABLE IF EXISTS deliveries CASCADE;
CREATE TABLE deliveries (
    delivery_id         VARCHAR(12)   NOT NULL,
    delivery_date       DATE,
    customer_id         VARCHAR(12)   NOT NULL,
    courier_id          VARCHAR(13),
    city                VARCHAR(40),
    time_taken_minutes  INTEGER,
    delivery_status     VARCHAR(20),
    revenue_gbp         DECIMAL(8,2),
    time_taken_minutes_outlier  BOOLEAN,
    revenue_on_failed_flag  BOOLEAN,
    realised_revenue_gbp         DECIMAL(8,2),
    PRIMARY KEY (delivery_id),
    FOREIGN KEY (customer_id) REFERENCES customers (customer_id),
    FOREIGN KEY (courier_id)  REFERENCES couriers  (courier_id)
);

DROP TABLE IF EXISTS incidents CASCADE;
CREATE TABLE incidents (
    incident_id        VARCHAR(12)   NOT NULL,
    delivery_id        VARCHAR(12)   NOT NULL,
    incident_date      DATE,
    incident_type      VARCHAR(40),
    resolution_status  VARCHAR(20),
    PRIMARY KEY (incident_id),
    FOREIGN KEY (delivery_id) REFERENCES deliveries (delivery_id)
);

--CURATED VIEW 
DROP VIEW IF EXISTS vw_delivery_curated;
CREATE OR REPLACE VIEW vw_delivery_curated AS
SELECT
    d.delivery_id,
    d.delivery_date,
    d.city AS delivery_city,
    d.time_taken_minutes,
    d.delivery_status,
    -- revenue: gross, realised (post-failure), and the loss between them
    d.revenue_gbp,
    d.realised_revenue_gbp,
    (d.revenue_gbp - d.realised_revenue_gbp) AS revenue_lost,
    d.revenue_on_failed_flag,
    -- customer context
    c.customer_id,
    c.customer_size,
    c.city AS customer_city,
    c.industry,
    c.payment_terms_days,
    -- courier context (NULL for subcontracted deliveries)
    co.courier_id,
    co.employment_type,
    co.shift_pattern,
    co.city AS courier_city,
    CASE WHEN co.courier_id IS NULL THEN 'Subcontractor'
         ELSE 'In-house' END AS courier_source,
    -- incident rollup
    COALESCE(i.incident_count, 0) AS incident_count,
    CASE WHEN COALESCE(i.incident_count, 0) > 0 THEN 1 ELSE 0 END AS had_incident
FROM deliveries d
JOIN customers c ON d.customer_id = c.customer_id
LEFT JOIN couriers co ON d.courier_id  = co.courier_id
LEFT JOIN (
    SELECT delivery_id, COUNT(*) AS incident_count
    FROM incidents
    GROUP BY delivery_id
) i                     ON d.delivery_id = i.delivery_id;


--view 2

DROP VIEW IF EXISTS vw_customer_churn;
CREATE OR REPLACE VIEW vw_customer_churn AS
WITH per_customer AS (
    SELECT
        c.customer_id,
        c.customer_size,
        c.city,
        c.industry,
        c.payment_terms_days,
        COUNT(d.delivery_id) AS total_deliveries,
        SUM(d.revenue_gbp) AS total_revenue_gross,
        SUM(d.realised_revenue_gbp) AS total_revenue_realised,
        ROUND(AVG(d.time_taken_minutes), 1) AS avg_time_taken,
        -- raw counts in each window
        SUM(CASE WHEN d.delivery_date <  DATE '2025-05-01' THEN 1 ELSE 0 END) AS deliveries_baseline,
        SUM(CASE WHEN d.delivery_date >= DATE '2025-05-01' THEN 1 ELSE 0 END) AS deliveries_recent
    FROM customers c
    LEFT JOIN deliveries d ON c.customer_id = d.customer_id
    GROUP BY c.customer_id, c.customer_size, c.city, c.industry, c.payment_terms_days
),
incident_rate AS (
    SELECT
        d.customer_id,
        ROUND(COUNT(i.incident_id)::DECIMAL / NULLIF(COUNT(DISTINCT d.delivery_id), 0), 4) AS incident_rate
    FROM deliveries d
    LEFT JOIN incidents i ON d.delivery_id = i.delivery_id
    GROUP BY d.customer_id
)
SELECT
    p.customer_id,
    p.customer_size,
    p.city,
    p.industry,
    p.payment_terms_days,
    p.total_deliveries,
    ROUND(p.total_revenue_gross, 2) AS total_revenue_gross,
    ROUND(p.total_revenue_realised, 2)AS total_revenue_realised,
    p.avg_time_taken,
    p.deliveries_baseline,
    p.deliveries_recent,
    -- baseline monthly avg (7 months) vs recent monthly avg (2 months)
    ROUND(p.deliveries_baseline / 7.0, 2) AS baseline_monthly_avg,
    ROUND(p.deliveries_recent  / 2.0, 2) AS recent_monthly_avg,
    COALESCE(ir.incident_rate, 0) AS incident_rate,
    CASE
        WHEN p.deliveries_baseline = 0 THEN NULL
        WHEN (p.deliveries_recent / 2.0) < 0.5 * (p.deliveries_baseline / 7.0) THEN 1
        ELSE 0
    END AS churn_label
FROM per_customer p
LEFT JOIN incident_rate ir ON p.customer_id = ir.customer_id;
