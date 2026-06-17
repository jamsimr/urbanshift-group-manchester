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

