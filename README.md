1. Úvod a popis zdrojových dát

Tento projekt sa zameriava na analýzu predajov v kamenných predajniach retailového reťazca pomocou datasetu TPC-DS 10TB, ktorý je dostupný v Snowflake ako vzorový dataset (SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL).

Prečo tento dataset?
TPC-DS je štandardný benchmark pre dátové sklady a obsahuje realistické retailové dáta (predaje, zákazníci, produkty, obchody, časové údaje). Umožňuje analyzovať tržby, ziskovosť, sezónnosť, výkonnosť predajní a segmentáciu zákazníkov.

Biznis proces, ktorý dáta podporujú: 
- Predaj tovaru v kamenných predajniach  
- Analýza tržieb, zisku a efektivity propagácií  
- Identifikácia top produktov a kategórií  
- Sezónne trendy a výkonnosť jednotlivých predajní  
- Segmentácia zákazníkov podľa regiónu a štátu

Typy údajov:  
- Časové (dátumy predajov)  
- Geografické (štáty, regióny, mestá)  
- Produktové (kategórie, značky)  
- Transakčné (množstvo, cena, zisk)





ERD diagram pôvodnej dátovej štruktúry  

<img width="833" height="564" alt="image" src="https://github.com/user-attachments/assets/4fd62711-a0f3-4a48-b57f-2f672764e35c" />









2. Návrh dimenzionálneho modelu

Navrhnutý hviezdicový model (Star Schema) obsahuje 1 faktovú tabuľku a 4 dimenzie. Model je navrhnutý podľa Kimballovej metodológie pre jednoduchú a rýchlu analýzu predajov.

<img width="944" height="616" alt="image" src="https://github.com/user-attachments/assets/a3c81110-11f5-4037-ada7-04c2b42d0f64" />



	







Dimenzie

DIM_DATE (SCD Type 0)

•	slúži na časovú analýzu predajov

•	umožňuje filtrovať a agregovať dáta podľa dňa, mesiaca, roka alebo štvrťroka

•	podporuje sezónne trendy (napr. vianočné predaje, letné výpredaje)


DIM_CUSTOMER (SCD Type 2)

•	poskytuje informácie o zákazníkoch (meno, mesto, štát, krajina)

•	umožňuje segmentáciu zákazníkov podľa geografického pôvodu

•	sleduje zmeny v adrese alebo segmente (historické zmeny vďaka valid_from/to)

DIM_ITEM (SCD Type 1)

•	obsahuje detaily o produktoch (názov, kategória, trieda, značka)

•	slúži na analýzu predajov podľa kategórií a značiek

•	umožňuje identifikovať najpredávanejšie produkty a kategórie

DIM_STORE (SCD Type 1)

•	poskytuje informácie o predajniach (názov, mesto, štát, región)

•	umožňuje analyzovať výkonnosť jednotlivých obchodov a regiónov

•	podporuje porovnávanie predajov podľa lokality (štát, kraj)


Faktová tabuľka – FACT_STORE_SALES
-	sales_sk: INT [primárny kľúč] 
-	sales_amount: DECIMAL(12,2) 
-	quantity: INT 
-	net_profit: DECIMAL(12,2) 
-	running_total_sales: DECIMAL(14,2) 
-	customer_rank_by_sales: INT 
-	dim_date_date_sk: INT [cudzí kľúč → DIM_DATE.date_sk] 
-	dim_customer_customer_sk: INT [cudzí kľúč → DIM_CUSTOMER.customer_sk]
-	dim_item_item_sk: INT [cudzí kľúč → DIM_ITEM.item_sk] 
-	dim_store_store_sk: INT [cudzí kľúč → DIM_STORE.store_sk]
 3. ELT proces v Snowflake
ELT proces pozostáva z troch hlavných fáz: extrahovanie (Extract), načítanie (Load) a transformácia (Transform). Tento proces bol implementovaný v Snowflake s cieľom pripraviť zdrojové dáta z benchmarkového datasetu TPC-DS 10TB do viacdimenzionálneho modelu vhodného na analýzu a vizualizáciu.

3.1	Extract (Extrahovanie dát)
Dáta boli extrahované zo Snowflake Marketplace – schémy **SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL**. Na zníženie objemu sme obmedzili roky na 2001 a 2002 a použili 5 % vzorku predajov.

Príklad:
```sql
CREATE OR REPLACE TABLE stg_date AS 
SELECT * 
FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.DATE_DIM 
WHERE d_year IN (2001, 2002);
```
```sql
CREATE OR REPLACE TABLE stg_store_sales AS 
SELECT * 
FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.STORE_SALES SAMPLE (0.05) WHERE ss_sold_date_sk IN (SELECT d_date_sk FROM stg_date);
```







3.2 Load (Načítanie dát)
Staging tabuľky boli naplnené a následne použité ako zdroj pre ďalšie transformácie. Ďalšie staging tabuľky (pre zákazníkov, produkty a obchody) boli vytvorené priamo z originálnych tabuliek s použitím JOIN-ov a filtrovania.

Príklad:
```sql
CREATE OR REPLACE TABLE stg_customer AS
SELECT DISTINCT
    c.c_customer_sk AS customer_sk,
    c.c_first_name,
    c.c_last_name,
    a.ca_city AS city,
    a.ca_state AS state,
    a.ca_country AS country
FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.CUSTOMER c
LEFT JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.CUSTOMER_ADDRESS a
    ON c.c_current_addr_sk = a.ca_address_sk
WHERE c.c_customer_sk IN (
    SELECT DISTINCT ss_customer_sk FROM stg_store_sales
);
```
```sql
CREATE OR REPLACE TABLE stg_item AS
SELECT DISTINCT
    i.i_item_sk AS item_sk,
    i.i_item_id,
    i.i_item_desc,
    i.i_category,
    i.i_class,
    i.i_brand
FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.ITEM i
JOIN stg_store_sales ss ON i.i_item_sk = ss.ss_item_sk;
```
```sql
CREATE OR REPLACE TABLE stg_store AS
SELECT DISTINCT
    s.s_store_sk AS store_sk,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_county AS region,
    s.s_country
FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.STORE s
JOIN stg_store_sales ss ON s.s_store_sk = ss.ss_store_sk;
```
3.3 Transform (Transformácia dát)
V tejto fáze boli dáta vyčistené, deduplikované a transformované do dimenzií a faktovej tabuľky. Použili sme SCD Type 2 pre dim_customer (sledovanie zmien adresy) a SCD Type 1/0 pre ostatné dimenzie. Faktová tabuľka obsahuje dva window functiony (SUM OVER a RANK).

Príklad:
```sql
CREATE OR REPLACE TABLE dim_date AS
SELECT
    d_date_sk,
    d_date AS full_date,
    EXTRACT(DAY FROM d_date) AS day,
    d_moy AS month,
    CASE d_moy
        WHEN 1 THEN 'January' WHEN 2 THEN 'February' 
    END AS month_name,
    d_year AS year,
    d_qoy AS quarter
FROM stg_date;
```
```sql
CREATE OR REPLACE TABLE dim_customer AS
SELECT
    customer_sk,
    customer_sk AS customer_id,
    first_name,
    last_name,
    city,
    state,
    country,
    '2001-01-01'::DATE AS valid_from,
    '9999-12-31'::DATE AS valid_to,
    TRUE AS is_current
FROM stg_customer;
```

 
4. Vizualizácia dát

<img width="1181" height="657" alt="image" src="https://github.com/user-attachments/assets/51f26a04-3bd0-4e50-9f01-42d0e3e99cd1" />








Graf 1: Tržby podľa mesiacov
-	Tento stĺpcový graf zobrazuje celkové tržby rozdelené podľa mesiacov v rokoch 2001 a 2002.
```sql
SELECT 
    CONCAT(d.year, '-', LPAD(d.month, 2, '0')) AS year_month,
    d.year,
    d.month,
    SUM(f.sales_amount) AS total_sales
FROM fact_store_sales f
JOIN dim_date d ON f.dim_date_date_sk = d.date_sk
GROUP BY d.year, d.month
ORDER BY d.year, d.month;
```

Graf ukazuje výraznú sezónnosť predajov – najvyššie tržby sú zaznamenané v novembri a decembri (vianočná sezóna). V roku 2001 bol najvýraznejší vrchol v novembri, v roku 2002 v decembri. Tieto mesiace sú ideálne na plánovanie propagačných akcií a zvýšenie zásob.

Graf 2: Tržby podľa regiónu
-	Horizontálny stĺpcový graf zobrazuje celkové tržby podľa regiónu (county).
```sql
SELECT
    s.region,
    SUM(f.sales_amount) AS total_sales
FROM fact_store_sales f
JOIN dim_store s ON f.dim_store_store_sk = s.store_sk
GROUP BY s.region
ORDER BY total_sales DESC;
```
Najvyššie tržby generujú regióny ako Ziebach County a Abbeville County. Tieto oblasti majú pravdepodobne vyšší počet predajní alebo vyššiu kúpnu silu obyvateľov. Regióny s nízkymi tržbami môžu byť kandidátmi na optimalizáciu alebo zatvorenie menej výkonných predajní.

Graf 3: Top 10 kategórií podľa množstva
-	Horizontálny stĺpcový graf zobrazuje 10 najpredávanejších kategórií podľa celkového predaného množstva.
```sql
SELECT
    i.category,
    SUM(f.quantity) AS total_quantity
FROM fact_store_sales f
JOIN dim_item i ON f.dim_item_item_sk = i.item_sk
GROUP BY i.category
ORDER BY total_quantity DESC
LIMIT 10;
```
Najpredávanejšími kategóriami sú Shoes, Music, Jewelry a Sports – spolu viac ako 27 miliónov kusov. Tieto kategórie by mali byť prioritne zásobované a propagované, pretože tvoria hlavný objem predaja.

Graf 4: Výkonnosť predajní podľa štátu
-	Stĺpcový graf ukazuje celkové tržby podľa štátu.
```sql
SELECT
    s.state,
    SUM(f.sales_amount) AS total_sales
FROM fact_store_sales f
JOIN dim_store s ON f.dim_store_store_sk = s.store_sk
GROUP BY s.state
ORDER BY total_sales DESC;
```
Najvýkonnejšie štáty sú MD (Maryland) a WV (West Virginia) – dosahujú výrazne vyššie tržby ako ostatné. Tieto štáty by mali slúžiť ako vzor pre iné regióny (napr. prenos najlepších praktík z predajní v týchto štátoch).

Graf 5: Počet unikátnych zákazníkov podľa štátu
-	Stĺpcový graf zobrazuje počet unikátnych zákazníkov podľa štátu.
```sql
SELECT
    c.state,
    COUNT(DISTINCT c.customer_sk) AS unique_customers
FROM fact_store_sales f
JOIN dim_customer c ON f.dim_customer_customer_sk = c.customer_sk
GROUP BY c.state
ORDER BY unique_customers DESC;
```
Najviac unikátnych zákazníkov pochádza zo štátov GA (Georgia) a MD. Tieto štáty majú širokú zákaznícku základňu, čo môže byť spôsobené väčším počtom predajní alebo vyššou hustotou obyvateľstva. Je to ideálna cieľová skupina pre vernostné programy.



Graf 6: Priemerná hodnota nákupu podľa štátu
-	Stĺpcový graf ukazuje priemernú hodnotu jednej transakcie podľa štátu.
```sql
SELECT
    c.state,
    AVG(f.sales_amount) AS avg_sales_per_transaction
FROM fact_store_sales f
JOIN dim_customer c ON f.dim_customer_customer_sk = c.customer_sk
GROUP BY c.state
ORDER BY avg_sales_per_transaction DESC;
```
Priemerná hodnota nákupu je pomerne vyrovnaná naprieč štátmi (okolo 38–41 USD). Najvyššie hodnoty dosahujú štáty AK a GA. Tento stabilný priemer naznačuje konzistentnú kúpnu silu zákazníkov bez výrazných regionálnych rozdielov.
Dashboard poskytuje komplexný pohľad na dáta a umožňuje rýchle rozhodovanie v oblasti marketingu, zásobovania a optimalizácie predajnej siete.


Autori: Samuel Andreas Vývlek, Filip Šufliarsky

