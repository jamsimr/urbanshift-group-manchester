-- Query 1: Total Revenue
SELECT ROUND(SUM(revenue_gbp), 2) AS total_revenue_gbp
FROM deliveries;

-- Query 2: Revenue by Customer
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
SELECT
    d.city,
    COUNT(DISTINCT d.delivery_id) AS total_deliveries,
    ROUND(SUM(d.revenue_gbp), 2) AS total_revenue_gbp
FROM deliveries d
GROUP BY d.city
ORDER BY total_revenue_gbp DESC;

-- Query 6: Monthly Revenue Trend
SELECT
    DATE_TRUNC('month', delivery_date) AS delivery_month,
    COUNT(DISTINCT delivery_id) AS total_deliveries,
    ROUND(SUM(revenue_gbp), 2) AS monthly_revenue_gbp
FROM deliveries
GROUP BY DATE_TRUNC('month', delivery_date)
ORDER BY delivery_month;

-- Query 7: Delivery Volume by Customer
SELECT
    c.customer_id,
    c.customer_name,
    COUNT(DISTINCT d.delivery_id) AS total_deliveries
FROM customers c
JOIN deliveries d ON c.customer_id = d.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_deliveries DESC;

-- Query 8: Overall Incident Rate
SELECT
    COUNT(DISTINCT d.delivery_id) AS total_deliveries,
    COUNT(DISTINCT i.incident_id) AS total_incidents,
    ROUND(COUNT(DISTINCT i.incident_id) * 100.0 / NULLIF(COUNT(DISTINCT d.delivery_id), 0), 2) AS incident_rate_pct
FROM deliveries d
LEFT JOIN incidents i ON d.delivery_id = i.delivery_id;

-- Query 9: Incident Rate by City
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
SELECT
    incident_type,
    COUNT(DISTINCT incident_id) AS incident_count,
    ROUND(COUNT(DISTINCT incident_id) * 100.0 / SUM(COUNT(DISTINCT incident_id)) OVER (), 2) AS incident_percentage
FROM incidents
GROUP BY incident_type
ORDER BY incident_count DESC;

-- Query 13: Resolution Status Analysis
SELECT
    resolution_status,
    COUNT(DISTINCT incident_id) AS incident_count,
    ROUND(COUNT(DISTINCT incident_id) * 100.0 / SUM(COUNT(DISTINCT incident_id)) OVER (), 2) AS status_percentage
FROM incidents
GROUP BY resolution_status
ORDER BY incident_count DESC;

-- Query 14: Incident Type by Resolution Status
SELECT
    incident_type,
    resolution_status,
    COUNT(DISTINCT incident_id) AS incident_count
FROM incidents
GROUP BY incident_type, resolution_status
ORDER BY incident_type, incident_count DESC;

-- Query 15: Failed Delivery Rate
SELECT
    COUNT(DISTINCT delivery_id) AS total_deliveries,
    COUNT(DISTINCT CASE WHEN delivery_status = 'Failed' THEN delivery_id END) AS failed_deliveries,
    ROUND(COUNT(DISTINCT CASE WHEN delivery_status = 'Failed' THEN delivery_id END) * 100.0 / COUNT(DISTINCT delivery_id), 2) AS failed_delivery_rate_pct
FROM deliveries;

-- Query 16: Returned Delivery Rate
SELECT
    COUNT(DISTINCT delivery_id) AS total_deliveries,
    COUNT(DISTINCT CASE WHEN delivery_status = 'Returned' THEN delivery_id END) AS returned_deliveries,
    ROUND(COUNT(DISTINCT CASE WHEN delivery_status = 'Returned' THEN delivery_id END) * 100.0 / COUNT(DISTINCT delivery_id), 2) AS returned_delivery_rate_pct
FROM deliveries;

-- Query 17: Delivery Time by Delivery Status
SELECT
    delivery_status,
    COUNT(DISTINCT delivery_id) AS total_deliveries,
    ROUND(AVG(time_taken_minutes), 2) AS avg_delivery_time_minutes
FROM deliveries
GROUP BY delivery_status
ORDER BY avg_delivery_time_minutes DESC;

-- Query 18: Delivery Time vs Incident Occurrence
SELECT
    CASE WHEN i.incident_id IS NOT NULL THEN 'Incident' ELSE 'No Incident' END AS incident_flag,
    COUNT(DISTINCT d.delivery_id) AS total_deliveries,
    ROUND(AVG(d.time_taken_minutes), 2) AS avg_delivery_time_minutes
FROM deliveries d
LEFT JOIN incidents i ON d.delivery_id = i.delivery_id
GROUP BY CASE WHEN i.incident_id IS NOT NULL THEN 'Incident' ELSE 'No Incident' END;

-- Query 19: Monthly Delivery Volume by Customer
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
