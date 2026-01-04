/*
=============================================================================
DDL Script: Create Gold Views
=============================================================================
Script Purpose:
	-This script creates views for the Gold layer in the data warehouse
	-The Gold layer represents the final dimension and fact tables (Star Schema)
	-Each view performs transformations and combination of data from Silver layer to produce
	 a clean, rich, and business-ready data set

Usage: 
	-These views can be queried directly for analytics and reports
=============================================================================
*/


CREATE VIEW gold.dim_customers AS
SELECT
	ROW_NUMBER() OVER(ORDER BY ci.cst_id) AS customer_key, 
	ci.cst_id AS curtomer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS customer_firstname,
	ci.cst_lastname AS customer_lastname,
	cl.cntry AS country,
	CASE
		WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr --crm is the master
		ELSE COALESCE (ca.gen, 'n/a')
	END gender,
	ci.cst_marital_status AS marital_status,
	ca.bdate AS birth_date,
	ci.cst_create_date AS create_date
FROM silver.crm_cst_info ci
LEFT JOIN silver.erp_cust_az12 ca
ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 cl
ON ci.cst_key = cl.cid

CREATE VIEW gold.dim_products AS
SELECT
	ROW_NUMBER () OVER(ORDER BY po.prd_start_dt, po.prd_key) AS product_key,
	po.prd_id AS product_id,
	po.prd_key AS product_number,
	po.prd_nm AS product_name,
	po.cat_id AS category_id,
	pc.cat AS category,
	pc.subcat AS sub_category,
	pc.maintenance,
	po.prd_cost AS cost,
	po.prd_line AS product_line,
	po.prd_start_dt AS 'start_date'
FROM silver.crm_prd_info AS po
JOIN silver.erp_px_cat_g1v2 AS pc
ON po.cat_id=pc.id 
WHERE po.prd_end_dt IS NULL --Filter out historical data

CREATE VIEW gold.fact_sales AS
SELECT
	sd.sls_ord_num AS order_number,
	pr.product_key,
	cu.customer_key,
	sd.sls_sales AS sales_amount,
	sd.sls_quantity AS quantity,
	sd.sls_price AS price,
	sd.sls_order_dt AS order_date,
	sd.sls_ship_dt AS shipping_date,
	sd.sls_due_dt AS due_date
FROM silver.crm_sales_details AS sd
LEFT JOIN gold.dim_products AS pr
ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers AS cu
ON sd.sls_cust_id = cu.curtomer_id
