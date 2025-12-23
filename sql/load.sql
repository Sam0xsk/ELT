CREATE OR REPLACE TABLE dim_date AS
SELECT
    d_date_sk AS date_sk,
    d_date AS full_date,
    EXTRACT(DAY FROM d_date) AS day,
    d_moy AS month,
    d_year AS year,
    d_qoy AS quarter
FROM stg_date;

CREATE OR REPLACE TABLE dim_customer AS
SELECT
    customer_sk,
    customer_sk AS customer_id,
    first_name,
    last_name,
    city,
    state,
    country AS segment,
    '2001-01-01'::DATE AS valid_from,
    '9999-12-31'::DATE AS valid_to,
    TRUE AS is_current
FROM stg_customer;

CREATE OR REPLACE TABLE dim_item AS
SELECT
    item_sk,
    item_id AS idem_id,
    item_desc AS item_name,
    category,
    brand
FROM stg_item;

CREATE OR REPLACE TABLE dim_store AS
SELECT
    store_sk,
    store_sk AS store_id,
    store_name,
    city,
    state,
    county AS region
FROM stg_store;

CREATE OR REPLACE TABLE fact_store_sales AS
SELECT
    ROW_NUMBER() OVER (ORDER BY date_sk, customer_sk, item_sk) AS sales_sk,
    sales_amount,
    quantity,
    net_profit,
    SUM(sales_amount) OVER (PARTITION BY customer_sk ORDER BY date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_sales,
    RANK() OVER (PARTITION BY store_sk ORDER BY sales_amount DESC) AS customer_rank_by_sales,
    date_sk AS dim_date_date_sk,
    customer_sk AS dim_customer_customer_sk,
    item_sk AS dim_item_item_sk,
    store_sk AS dim_store_store_sk
FROM stg_store_sales;