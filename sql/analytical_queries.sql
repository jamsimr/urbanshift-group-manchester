-- Query 1: Total Revenue
-- Query 1: UrbanShift generated £491,888.94 across the analysis period, establishing the commercial baseline for performance evaluation.
SELECT ROUND(SUM(revenue_gbp), 2) AS total_revenue_gbp
FROM deliveries;

-- Query 2: Revenue by Customer
-- Query 2: Revenue is concentrated among a small number of strategic customer accounts, increasing commercial dependency and retention risk.
SELECT TOP 10 
    c.customer_id,
    c.customer_name,
    COUNT(DISTINCT d.delivery_id) AS total_deliveries,
    ROUND(SUM(d.revenue_gbp), 2) AS total_revenue_gbp,
    ROUND(SUM(d.revenue_gbp) / NULLIF(COUNT(DISTINCT d.delivery_id), 0), 2) AS revenue_per_delivery
FROM customers c
JOIN deliveries d ON c.customer_id = d.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_revenue_gbp DESC;

-- Query 3: Revenue by Customer Segment
-- Query 3: Large Accounts deliver the highest average revenue per customer despite Mid-size Retailers generating the greatest overall revenue.
SELECT
    c.customer_size,
    COUNT(DISTINCT c.customer_id) AS customer_count,
    COUNT(DISTINCT d.delivery_id) AS total_deliveries,
    ROUND(SUM(d.revenue_gbp), 2) AS total_revenue_gbp,
    ROUND(SUM(d.revenue_gbp) / NULLIF(COUNT(DISTINCT c.customer_id), 0), 2) AS avg_revenue_per_customer
FROM customers c
JOIN deliveries d ON c.customer_id = d.customer_id
GROUP BY c.customer_size
ORDER BY total_revenue_gbp DESC;

-- Query 4: Revenue by Industry
-- Query 4: Fashion contributes over 40% of total revenue, indicating significant sector concentration and limited revenue diversification.
SELECT
    c.industry,
    COUNT(DISTINCT c.customer_id) AS customer_count,
    COUNT(DISTINCT d.delivery_id) AS total_deliveries,
    ROUND(SUM(d.revenue_gbp), 2) AS total_revenue_gbp,
    ROUND(SUM(d.revenue_gbp) * 100.0 / SUM(SUM(d.revenue_gbp)) OVER (), 2) AS revenue_percentage
FROM customers c
JOIN deliveries d ON c.customer_id = d.customer_id
GROUP BY c.industry
ORDER BY total_revenue_gbp DESC;

-- Query 5: Revenue by City
-- Query 5: London generates almost half of total company revenue, demonstrating substantial geographic concentration.
SELECT
    d.city,
    COUNT(DISTINCT d.delivery_id) AS total_deliveries,
    ROUND(SUM(d.revenue_gbp), 2) AS total_revenue_gbp
FROM deliveries d
GROUP BY d.city
ORDER BY total_revenue_gbp DESC;

-- Query 6: Monthly Revenue Trend
-- Query 6: Revenue follows a seasonal pattern, peaking in December before declining sharply in January and recovering gradually thereafter.
SELECT
    DATE_TRUNC('month', delivery_date) AS delivery_month,
    COUNT(DISTINCT delivery_id) AS total_deliveries,
    ROUND(SUM(revenue_gbp), 2) AS monthly_revenue_gbp
FROM deliveries
GROUP BY DATE_TRUNC('month', delivery_date)
ORDER BY delivery_month;

-- Query 7: Delivery Volume by Customer
-- Query 7: Customer revenue is primarily driven by delivery volume, with the highest-volume customers also generating the greatest revenue.
SELECT
    c.customer_id,
    c.customer_name,
    COUNT(DISTINCT d.delivery_id) AS total_deliveries
FROM customers c
JOIN deliveries d ON c.customer_id = d.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_deliveries DESC;

-- Query 8: Overall Incident Rate
-- Query 8: Approximately 22.8% of deliveries experience an operational incident, highlighting service quality as a key business challenge.
SELECT
    COUNT(DISTINCT d.delivery_id) AS total_deliveries,
    COUNT(DISTINCT i.incident_id) AS total_incidents,
    ROUND(COUNT(DISTINCT i.incident_id) * 100.0 / NULLIF(COUNT(DISTINCT d.delivery_id), 0), 2) AS incident_rate_pct
FROM deliveries d
LEFT JOIN incidents i ON d.delivery_id = i.delivery_id;

-- Query 9: Incident Rate by City
-- Query 9: Operational risk varies geographically, with Manchester recording the highest incident rate despite lower delivery volumes than London.
SELECT
    d.city,
    COUNT(DISTINCT d.delivery_id) AS total_deliveries,
    COUNT(DISTINCT i.incident_id) AS total_incidents,
    ROUND(COUNT(DISTINCT i.incident_id) * 100.0 / NULLIF(COUNT(DISTINCT d.delivery_id), 0), 2) AS incident_rate_pct
FROM deliveries d
LEFT JOIN incidents i ON d.delivery_id = i.delivery_id
GROUP BY d.city
ORDER BY incident_rate_pct DESC;

-- Query 10: Incident Rate by Employment Type
-- Query 10: Contracted couriers experience substantially higher incident rates than employed couriers, suggesting employment type influences service quality.
SELECT
    COALESCE(c.employment_type, 'Missing / Subcontractor') AS employment_type,
    COUNT(DISTINCT d.delivery_id) AS total_deliveries,
    COUNT(DISTINCT i.incident_id) AS total_incidents,
    ROUND(COUNT(DISTINCT i.incident_id) * 100.0 / NULLIF(COUNT(DISTINCT d.delivery_id), 0), 2) AS incident_rate_pct
FROM deliveries d
LEFT JOIN couriers c ON d.courier_id = c.courier_id
LEFT JOIN incidents i ON d.delivery_id = i.delivery_id
GROUP BY COALESCE(c.employment_type, 'Missing / Subcontractor')
ORDER BY incident_rate_pct DESC;

-- Query 11: Incident Rate by Shift Pattern
-- Query 11: Night shift operations exhibit almost double the incident rate of day shifts, identifying shift pattern as a major operational risk factor.
SELECT
    COALESCE(c.shift_pattern, 'Missing / Subcontractor') AS shift_pattern,
    COUNT(DISTINCT d.delivery_id) AS total_deliveries,
    COUNT(DISTINCT i.incident_id) AS total_incidents,
    ROUND(COUNT(DISTINCT i.incident_id) * 100.0 / NULLIF(COUNT(DISTINCT d.delivery_id), 0), 2) AS incident_rate_pct
FROM deliveries d
LEFT JOIN couriers c ON d.courier_id = c.courier_id
LEFT JOIN incidents i ON d.delivery_id = i.delivery_id
GROUP BY COALESCE(c.shift_pattern, 'Missing / Subcontractor')
ORDER BY incident_rate_pct DESC;

-- Query 12: Incident Type Distribution
-- Query 12: Damaged parcels, late deliveries and customer complaints account for approximately 60% of all operational incidents.
SELECT
    incident_type,
    COUNT(DISTINCT incident_id) AS incident_count,
    ROUND(COUNT(DISTINCT incident_id) * 100.0 / SUM(COUNT(DISTINCT incident_id)) OVER (), 2) AS incident_percentage
FROM incidents
GROUP BY incident_type
ORDER BY incident_count DESC;

-- Query 13: Resolution Status Analysis
-- Query 13: Although around 80% of incidents are resolved, unresolved cases continue to represent a significant operational workload.
SELECT
    resolution_status,
    COUNT(DISTINCT incident_id) AS incident_count,
    ROUND(COUNT(DISTINCT incident_id) * 100.0 / SUM(COUNT(DISTINCT incident_id)) OVER (), 2) AS status_percentage
FROM incidents
GROUP BY resolution_status
ORDER BY incident_count DESC;

-- Query 14: Incident Type by Resolution Status
-- Query 14: Customer complaints and damaged parcels generate the largest numbers of pending and escalated incidents.
SELECT
    incident_type,
    resolution_status,
    COUNT(DISTINCT incident_id) AS incident_count
FROM incidents
GROUP BY incident_type, resolution_status
ORDER BY incident_type, incident_count DESC;

-- Query 15: Failed Delivery Rate
-- Query 15: Failed deliveries represent approximately 5% of all deliveries, indicating measurable opportunities for operational improvement.
SELECT
    COUNT(DISTINCT delivery_id) AS total_deliveries,
    COUNT(DISTINCT CASE WHEN delivery_status = 'Failed' THEN delivery_id END) AS failed_deliveries,
    ROUND(COUNT(DISTINCT CASE WHEN delivery_status = 'Failed' THEN delivery_id END) * 100.0 / COUNT(DISTINCT delivery_id), 2) AS failed_delivery_rate_pct
FROM deliveries;

-- Query 16: Returned Delivery Rate
-- Query 16: Returned deliveries account for around 3% of deliveries, creating additional handling costs and operational inefficiencies.
SELECT
    COUNT(DISTINCT delivery_id) AS total_deliveries,
    COUNT(DISTINCT CASE WHEN delivery_status = 'Returned' THEN delivery_id END) AS returned_deliveries,
    ROUND(COUNT(DISTINCT CASE WHEN delivery_status = 'Returned' THEN delivery_id END) * 100.0 / COUNT(DISTINCT delivery_id), 2) AS returned_delivery_rate_pct
FROM deliveries;

-- Query 17: Delivery Time by Delivery Status#
-- Query 17: Delivery duration remains consistent across delivery outcomes, indicating delivery time is not a significant driver of failed or returned deliveries.
SELECT
    delivery_status,
    COUNT(DISTINCT delivery_id) AS total_deliveries,
    ROUND(AVG(time_taken_minutes), 2) AS avg_delivery_time_minutes
FROM deliveries
GROUP BY delivery_status
ORDER BY avg_delivery_time_minutes DESC;

-- Query 18: Delivery Time vs Incident Occurrence
-- Query 18: Average delivery times are identical for deliveries with and without incidents, suggesting operational risk is driven by other factors.
SELECT
    CASE WHEN i.incident_id IS NOT NULL THEN 'Incident' ELSE 'No Incident' END AS incident_flag,
    COUNT(DISTINCT d.delivery_id) AS total_deliveries,
    ROUND(AVG(d.time_taken_minutes), 2) AS avg_delivery_time_minutes
FROM deliveries d
LEFT JOIN incidents i ON d.delivery_id = i.delivery_id
GROUP BY CASE WHEN i.incident_id IS NOT NULL THEN 'Incident' ELSE 'No Incident' END;

-- Query 19: Monthly Delivery Volume by Customer
-- Query 19: Sustained reductions in monthly delivery activity provide an early indicator of potential customer churn.
SELECT
    c.customer_id,
    c.customer_name,
    DATE_TRUNC('month', d.delivery_date) AS delivery_month,
    COUNT(DISTINCT d.delivery_id) AS monthly_deliveries
FROM customers c
JOIN deliveries d ON c.customer_id = d.customer_id
GROUP BY c.customer_id, c.customer_name, DATE_TRUNC('month', d.delivery_date)
ORDER BY c.customer_id, delivery_month;

-- Query 20: Monthly Revenue Trend by Customer
-- Query 20: Declining customer revenue closely mirrors declining delivery volumes, reinforcing revenue trend as a leading churn indicator.
SELECT
    c.customer_id,
    c.customer_name,
    DATE_TRUNC('month', d.delivery_date) AS delivery_month,
    ROUND(SUM(d.revenue_gbp), 2) AS monthly_revenue_gbp
FROM customers c
JOIN deliveries d ON c.customer_id = d.customer_id
GROUP BY c.customer_id, c.customer_name, DATE_TRUNC('month', d.delivery_date)
ORDER BY c.customer_id, delivery_month;

-- Query 21: Customer Incident Rate
-- Query 21: Customers experiencing incident rates above the company average are exposed to greater service quality risk and potential dissatisfaction.
SELECT
    c.customer_id,
    c.customer_name,
    COUNT(DISTINCT d.delivery_id) AS total_deliveries,
    COUNT(DISTINCT i.incident_id) AS total_incidents,
    ROUND(COUNT(DISTINCT i.incident_id) * 100.0 / NULLIF(COUNT(DISTINCT d.delivery_id), 0), 2) AS customer_incident_rate_pct
FROM customers c
JOIN deliveries d ON c.customer_id = d.customer_id
LEFT JOIN incidents i ON d.delivery_id = i.delivery_id
GROUP BY c.customer_id, c.customer_name
ORDER BY customer_incident_rate_pct DESC;

-- Query 22: Customer Failed Delivery Rate
-- Query 22: Elevated failed delivery rates are concentrated among specific customer accounts, indicating targeted operational intervention opportunities.
SELECT
    c.customer_id,
    c.customer_name,
    COUNT(DISTINCT d.delivery_id) AS total_deliveries,
    COUNT(DISTINCT CASE WHEN d.delivery_status = 'Failed' THEN d.delivery_id END) AS failed_deliveries,
    ROUND(COUNT(DISTINCT CASE WHEN d.delivery_status = 'Failed' THEN d.delivery_id END) * 100.0 / NULLIF(COUNT(DISTINCT d.delivery_id), 0), 2) AS failed_delivery_rate_pct
FROM customers c
JOIN deliveries d ON c.customer_id = d.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY failed_delivery_rate_pct DESC;

-- Query 23: Customer Service Quality vs Activity
-- Query 23: Customers experiencing higher incident rates also demonstrate the greatest reductions in delivery activity, suggesting service quality is associated with declining customer engagement.
WITH customer_summary AS (
    SELECT
        c.customer_id,
        c.customer_name,
        COUNT(DISTINCT d.delivery_id) AS total_deliveries,
        COUNT(DISTINCT i.incident_id) AS total_incidents,
        ROUND(COUNT(DISTINCT i.incident_id) * 100.0 / NULLIF(COUNT(DISTINCT d.delivery_id), 0), 2) AS incident_rate_pct
    FROM customers c
    JOIN deliveries d ON c.customer_id = d.customer_id
    LEFT JOIN incidents i ON d.delivery_id = i.delivery_id
    GROUP BY c.customer_id, c.customer_name
),
monthly_activity AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', delivery_date) AS delivery_month,
        COUNT(DISTINCT delivery_id) AS monthly_deliveries
    FROM deliveries
    GROUP BY customer_id, DATE_TRUNC('month', delivery_date)
),
first_last AS (
    SELECT
        customer_id,
        MAX(CASE WHEN rn_first = 1 THEN monthly_deliveries END) AS first_month_deliveries,
        MAX(CASE WHEN rn_last = 1 THEN monthly_deliveries END) AS last_month_deliveries
    FROM (
        SELECT
            *,
            ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY delivery_month ASC) AS rn_first,
            ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY delivery_month DESC) AS rn_last
        FROM monthly_activity
    ) x
    GROUP BY customer_id
)
SELECT
    cs.customer_id,
    cs.customer_name,
    cs.total_deliveries,
    cs.total_incidents,
    cs.incident_rate_pct,
    fl.first_month_deliveries,
    fl.last_month_deliveries,
    fl.last_month_deliveries - fl.first_month_deliveries AS delivery_change,
    ROUND((fl.last_month_deliveries - fl.first_month_deliveries) * 100.0 / NULLIF(fl.first_month_deliveries, 0), 2) AS delivery_change_pct
FROM customer_summary cs
JOIN first_last fl ON cs.customer_id = fl.customer_id
ORDER BY incident_rate_pct DESC;

-- Query 24: Churn Model Feature Exploration
-- Query 24: Customer behaviour, operational performance and service quality metrics provide a robust feature set for predictive churn modelling within SageMaker Canvas.
SELECT TOP 10
    c.customer_id,
    c.customer_name,
    c.customer_size,
    c.industry,
    c.city,
    c.payment_terms_days,
    COUNT(DISTINCT d.delivery_id) AS total_deliveries,
    ROUND(SUM(d.revenue_gbp), 2) AS total_revenue_gbp,
    ROUND(AVG(d.time_taken_minutes), 2) AS avg_delivery_time_minutes,
    COUNT(DISTINCT CASE WHEN d.delivery_status = 'Failed' THEN d.delivery_id END) AS failed_deliveries,
    COUNT(DISTINCT CASE WHEN d.delivery_status = 'Returned' THEN d.delivery_id END) AS returned_deliveries,
    COUNT(DISTINCT i.incident_id) AS total_incidents,
    COUNT(DISTINCT CASE WHEN i.resolution_status = 'Escalated' THEN i.incident_id END) AS escalated_incidents,
    COUNT(DISTINCT CASE WHEN i.resolution_status = 'Pending' THEN i.incident_id END) AS pending_incidents,
    ROUND(COUNT(DISTINCT i.incident_id) * 100.0 / NULLIF(COUNT(DISTINCT d.delivery_id), 0), 2) AS incident_rate_pct
FROM customers c
LEFT JOIN deliveries d ON c.customer_id = d.customer_id
LEFT JOIN incidents i ON d.delivery_id = i.delivery_id
GROUP BY
    c.customer_id,
    c.customer_name,
    c.customer_size,
    c.industry,
    c.city,
    c.payment_terms_days
ORDER BY incident_rate_pct DESC;


-- Cleaning Check 
-- Row counts
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'couriers', COUNT(*) FROM couriers
UNION ALL
SELECT 'deliveries', COUNT(*) FROM deliveries
UNION ALL
SELECT 'incidents', COUNT(*) FROM incidents;

-- Duplicate delivery IDs
SELECT delivery_id, COUNT(*) AS duplicate_count
FROM deliveries
GROUP BY delivery_id
HAVING COUNT(*) > 1;

-- Missing key values in deliveries
SELECT
    COUNT(*) AS total_rows,
    COUNT(CASE WHEN delivery_id IS NULL THEN 1 END) AS missing_delivery_id,
    COUNT(CASE WHEN customer_id IS NULL THEN 1 END) AS missing_customer_id,
    COUNT(CASE WHEN courier_id IS NULL THEN 1 END) AS missing_courier_id
FROM deliveries;

-- Unmatched customer IDs
SELECT COUNT(*) AS unmatched_customers
FROM deliveries d
LEFT JOIN customers c
    ON d.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Unmatched incident delivery IDs
SELECT COUNT(*) AS unmatched_incidents
FROM incidents i
LEFT JOIN deliveries d
    ON i.delivery_id = d.delivery_id
WHERE d.delivery_id IS NULL;

-- Check date ranges
SELECT
    MIN(delivery_date) AS earliest_delivery,
    MAX(delivery_date) AS latest_delivery
FROM deliveries;

SELECT
    MIN(incident_date) AS earliest_incident,
    MAX(incident_date) AS latest_incident
FROM incidents;

-- Check city standardisation
SELECT city, COUNT(*) AS row_count
FROM deliveries
GROUP BY city
ORDER BY city;

-- Check category values
SELECT delivery_status, COUNT(*)
FROM deliveries
GROUP BY delivery_status;

SELECT incident_type, COUNT(*)
FROM incidents
GROUP BY incident_type;

SELECT resolution_status, COUNT(*)
FROM incidents
GROUP BY resolution_status;
