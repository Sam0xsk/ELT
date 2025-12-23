-- Tržby podľa mesiacov
SELECT 
    CONCAT(d.year, '-', LPAD(d.month, 2, '0')) AS year_month,
    d.year,
    d.month,
    SUM(f.sales_amount) AS total_sales
FROM fact_store_sales f
JOIN dim_date d ON f.dim_date_date_sk = d.date_sk
GROUP BY d.year, d.month
ORDER BY d.year, d.month;

-- Tržby podľa regiónu
SELECT
    s.region,
    SUM(f.sales_amount) AS total_sales
FROM fact_store_sales f
JOIN dim_store s ON f.dim_store_store_sk = s.store_sk
GROUP BY s.region
ORDER BY total_sales DESC;

-- Top 10 kategórií podľa množstva
SELECT
    i.category,
    SUM(f.quantity) AS total_quantity
FROM fact_store_sales f
JOIN dim_item i ON f.dim_item_item_sk = i.item_sk
GROUP BY i.category
ORDER BY total_quantity DESC
LIMIT 10;

-- Výkonnosť predajní
SELECT
    s.store_name,
    s.state,
    SUM(f.sales_amount) AS total_sales
FROM fact_store_sales f
JOIN dim_store s
    ON f.dim_store_store_sk = s.store_sk
GROUP BY s.store_name, s.state
ORDER BY total_sales DESC;

-- Počet unikátnych zákazníkov podľa štátu
SELECT
    c.state,
    COUNT(DISTINCT c.customer_sk) AS unique_customers,
    SUM(f.sales_amount) AS total_sales
FROM fact_store_sales f
JOIN dim_customer c ON f.dim_customer_customer_sk = c.customer_sk
GROUP BY c.state
ORDER BY unique_customers DESC;

-- Priemerná hodnota nákupu podľa štátu
SELECT
    c.state,
    AVG(f.sales_amount) AS avg_sales_per_transaction,
    COUNT(*) AS transaction_count,
    SUM(f.sales_amount) AS total_sales
FROM fact_store_sales f
JOIN dim_customer c ON f.dim_customer_customer_sk = c.customer_sk
GROUP BY c.state
ORDER BY avg_sales_per_transaction DESC;