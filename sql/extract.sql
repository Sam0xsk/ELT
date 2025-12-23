USE WAREHOUSE WOODCHUCK_WH;
USE DATABASE WOODCHUCK_DB;
CREATE OR REPLACE SCHEMA projekt;
USE SCHEMA projekt;

CREATE OR REPLACE TABLE stg_date AS
SELECT
    d_date_sk,
    d_date,
    d_day_name,
    d_moy,
    CASE d_moy
        WHEN 1 THEN 'January'
        WHEN 2 THEN 'February'
        WHEN 3 THEN 'March'
        WHEN 4 THEN 'April'
        WHEN 5 THEN 'May'
        WHEN 6 THEN 'June'
        WHEN 7 THEN 'July'
        WHEN 8 THEN 'August'
        WHEN 9 THEN 'September'
        WHEN 10 THEN 'October'
        WHEN 11 THEN 'November'
        WHEN 12 THEN 'December'
    END AS d_month_name,
    d_year,
    d_qoy
FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.DATE_DIM
WHERE d_year IN (2001, 2002);

CREATE OR REPLACE TABLE stg_customer AS
SELECT DISTINCT
    c.c_customer_sk AS customer_sk,
    c.c_first_name AS first_name,
    c.c_last_name AS last_name,
    c.c_current_addr_sk AS current_addr_sk,
    a.ca_city AS city,
    a.ca_state AS state,
    a.ca_country AS country
FROM snowflake_sample_data.tpcds_sf10tcl.customer c
LEFT JOIN snowflake_sample_data.tpcds_sf10tcl.customer_address a
    ON c.c_current_addr_sk = a.ca_address_sk
WHERE c.c_customer_sk IN (
    SELECT DISTINCT ss_customer_sk
    FROM snowflake_sample_data.tpcds_sf10tcl.store_sales ss
    WHERE ss_sold_date_sk IN (
        SELECT d_date_sk FROM stg_date
    )
);

CREATE OR REPLACE TABLE stg_item AS
SELECT DISTINCT
    i.i_item_sk AS item_sk,
    i.i_item_id AS item_id,
    i.i_item_desc AS item_desc,
    i.i_category AS category,
    i.i_class AS class,
    i.i_brand AS brand
FROM snowflake_sample_data.tpcds_sf10tcl.item i
JOIN snowflake_sample_data.tpcds_sf10tcl.store_sales ss
    ON i.i_item_sk = ss.ss_item_sk
WHERE ss.ss_sold_date_sk IN (
    SELECT d_date_sk FROM stg_date
);

CREATE OR REPLACE TABLE stg_store AS
SELECT DISTINCT
    s.s_store_sk AS store_sk,
    s.s_store_name AS store_name,
    s.s_city AS city,
    s.s_state AS state,
    s.s_country AS country,
    s.s_county AS county
FROM snowflake_sample_data.tpcds_sf10tcl.store s
JOIN snowflake_sample_data.tpcds_sf10tcl.store_sales ss
    ON s.s_store_sk = ss.ss_store_sk
WHERE ss.ss_sold_date_sk IN (
    SELECT d_date_sk FROM stg_date
);

CREATE OR REPLACE TABLE stg_store_sales AS
SELECT
    ss_sold_date_sk AS date_sk,
    ss_customer_sk AS customer_sk,
    ss_item_sk AS item_sk,
    ss_store_sk AS store_sk,
    ss_quantity AS quantity,
    ss_sales_price AS sales_amount,
    ss_net_profit AS net_profit
FROM snowflake_sample_data.tpcds_sf10tcl.store_sales SAMPLE (0.05)
WHERE ss_sold_date_sk BETWEEN 2451911 AND 2452640;