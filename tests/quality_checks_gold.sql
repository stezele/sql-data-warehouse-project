/* 
==============================================================================================
Quality Checks
==============================================================================================
Script Purpose:
  This script performs quality checks to validate the integrity, consistency,
  and accuracy of the Gold layer. These checks ensure:
    - Uniquess of surrogate keys in dimension tables.
    - Referencial integrity between fact and dimension tables.
    - Validation of relationships in the data model for analytical purposes.

  Usage Notes:
    - Run these checks after data loading Silver Layer.
    - Investigate and resolve any discrepancies found during the checks.
============================================================================================
*/

-- ==========================================================================================
--  Checking 'gold.dim_customers'
-- ==========================================================================================

-- Check for uniquess of Customer key in gold.dim_customers
-- Expectation: No results

SELECT cst_id, COUNT(*)
FROM(
	SELECT 
		ci.cst_id,
		ci.cst_key,
		ci.cst_firstname,
		ci.cst_lastname,
		ci.cst_marital_status,
		ci.cst_gndr,
		ci.cst_create_date,
		ca.bdate,
		ca.gen,
		la.cntry
	FROM silver.crm_cust_info ci
	LEFT JOIN silver.erp_cust_az12 ca
		ON ci.cst_key = ca.cid
	LEFT JOIN silver.erp_loc_a101 la
		ON ci.cst_key = la.cid
)t GROUP BY cst_id
HAVING COUNT(*) > 1;



SELECT
	ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
	la.cntry AS country,
	ci.cst_marital_status AS marital_status,
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the Master for gender info
		 ELSE COALESCE(ca.gen, 'n/a')
	END AS gender,
	ca.bdate AS birthdate,
	ci.cst_create_date AS create_date		
	FROM silver.crm_cust_info ci
	LEFT JOIN silver.erp_cust_az12 ca
		ON ci.cst_key = ca.cid
	LEFT JOIN silver.erp_loc_a101 la
		ON ci.cst_key = la.cid;

-- Data integration 

SELECT DISTINCT
	ci.cst_gndr,
	ca.gen,
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the Master for gender info
		 ELSE COALESCE(ca.gen, 'n/a')
	END AS new_gen
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
	ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
	ON ci.cst_key = la.cid
ORDER BY 1, 2;

SELECT * FROM gold.dim_customers;

-- ==========================================================================================
--  Checking 'gold.dim_customers'
-- ==========================================================================================

-- Check for uniquess of Customer key in gold.dim_customers
-- Expectation: No results

SELECT
	pn.prd_id,
	pn.cat_id,
	pn.prd_key,
	pn.prd_nm,
	pn.prd_cost,
	pn.prd_line,
	pn.prd_start_dt,
	pn.prd_end_dt,
	pc.cat,
	pc.subcat,
	pc.maintenance
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2  pc
	ON pn.cat_id = pc.id
WHERE prd_end_dt IS NULL; -- Filter out all historical data

-- check product key

SELECT prd_key, COUNT(*) FROM (

SELECT
	pn.prd_id,
	pn.cat_id,
	pn.prd_key,
	pn.prd_cost,
	pn.prd_line,
	pn.prd_start_dt,
	pn.prd_end_dt,
	pc.cat,
	pc.subcat,
	pc.maintenance
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2  pc
	ON pn.cat_id = pc.id
WHERE prd_end_dt IS NULL
)t GROUP BY prd_key
HAVING COUNT(*) > 1;


SELECT * FROM gold.dim_products;

-- ==========================================================================================
--  Checking 'gold.dim_customers'
-- ==========================================================================================

-- Check for uniquess of Customer key in gold.dim_customers
-- Expectation: No results

SELECT
	sd.sls_ord_num AS order_number,
	pr.product_key,
	cu.customer_key,
	sd.sls_order_dt AS order_date,
	sd.sls_ship_dt AS shipping_date,
	sd.sls_due_dt AS due_date,
	sd.sls_sales AS sales_amount,
	sd.sls_quantity AS quantity,
	sd.sls_price AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
	ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cu
	ON sd.sls_cust_id = cu.customer_id;

SELECT * FROM gold.dim_customers;
SELECT * FROM gold.dim_products;
