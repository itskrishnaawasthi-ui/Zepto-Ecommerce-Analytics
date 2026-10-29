USE zepto_analytics;
DROP TABLE IF EXISTS zepto_cleaned;
CREATE TABLE zepto_cleaned (
    product_id INT,
    category TEXT,
    name TEXT,
    mrp DECIMAL(10,2),
    discount_percent DECIMAL(5,2),
    available_quantity INT,
    discounted_selling_price DECIMAL(10,2),
    weight_in_gms DECIMAL(10,2),
    out_of_stock TINYINT,
    quantity INT,
    discount_amount DECIMAL(10,2),
    calculated_discount_percent DECIMAL(7,3),
    stock_status TEXT,
    discount_difference DECIMAL(10,4)
);

SHOW TABLES;
DESCRIBE zepto_cleaned;

SELECT * FROM zepto_cleaned
LIMIT 5;
-- Data check: the CSV has 3729 rows
SELECT COUNT(*) AS total_rows FROM zepto_cleaned;
SHOW TABLE STATUS FROM zepto_analytics;



-- Updating the discount difference to 2 decimal places permanently
-- Disabling safe update
SET SQL_SAFE_UPDATES = 0;
-- Running the query 
UPDATE zepto_cleaned
SET discount_difference=ROUND(discount_difference,2);
-- Enabling  the safe update  on (best practice)
SET SQL_SAFE_UPDATES=1;
SELECT discount_difference FROM zepto_cleaned
LIMIT 5;

-- 1.Insight:
SELECT COUNT(*) AS Total_products,COUNT(DISTINCT category) AS categories , ROUND(AVG(discount_percent),2) AS average_discount FROM zepto_cleaned;
-- Observation: The dataset contains 3729 total products spanning 14 unique categories with an overall average discount of 7.62%.

-- 2.Insight:
SELECT category,COUNT(*) AS products,ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM zepto_cleaned), 2) AS catalog_share_pct
FROM zepto_cleaned
GROUP BY category
ORDER BY products DESC;
-- Observation: Cooking Essentials and Munchies are tied for the largest catalog share at 13.78% of all listed items each.

-- 3.Insight:
SELECT category, ROUND(AVG(discount_percent),2) AS avg_discount
FROM zepto_cleaned
GROUP BY category
ORDER BY avg_discount DESC;
-- Fruits & Vegetables offers the highest average discount at 15.46%.

-- 4.Insight:
SELECT category, ROUND(AVG(out_of_stock) * 100, 2) AS oos_pct
FROM zepto_cleaned
GROUP BY category
ORDER BY oos_pct DESC;
-- Biscuits has the highest out-of-stock rate at 28.57%.

-- 5.Insight:
SELECT category, name, mrp
FROM zepto_cleaned
ORDER BY mrp DESC
LIMIT 10;
-- Borges Extra Light Olive Oil Bottle is the single most expensive item in the catalog, priced at Rs 2600.

-- 6.Insight:
-- How are products distributed across discount levels?
SELECT COUNT(*) AS total_products,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM zepto_cleaned), 2) AS product_share,
    CASE
        WHEN discount_percent = 0 THEN 'No Discount'
        WHEN discount_percent BETWEEN 0.01 AND 10 THEN 'LowDiscount (0-10%)'
        WHEN discount_percent BETWEEN 10.01 AND 25 THEN 'Medium Discount (10-25%)'
        ELSE 'High Discount (>25%)'
    END AS discount_band
    
FROM zepto_cleaned
GROUP BY discount_band
ORDER BY total_products DESC;
-- Observation: 1740 products are in the Low Discount band (0 to 10%).

-- 7.Insight:
-- Which categories have the most products with no discount?
SELECT
    z.category,
    COUNT(*) AS zero_discount_products,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM zepto_cleaned WHERE category = z.category), 2) AS zero_discount_share_pct
FROM zepto_cleaned z
WHERE z.discount_percent = 0
GROUP BY z.category
ORDER BY zero_discount_products DESC;
-- Observation: Cooking Essentials and Munchies have the most zero-discount products (139 each).

-- 8. Insight:
-- How are products distributed across price ranges?
SELECT
    CASE
        WHEN discounted_selling_price < 50 THEN 'Budget (< Rs 50)'
        WHEN discounted_selling_price BETWEEN 50 AND 199 THEN 'Mid-range (Rs 50-199)'
        WHEN discounted_selling_price BETWEEN 200 AND 499 THEN 'Premium (Rs 200-499)'
        ELSE 'Luxury (Rs 500+)'
    END AS price_band,
    COUNT(*) AS total_products,
    ROUND(AVG(discount_percent), 2) AS avg_discount
FROM zepto_cleaned
GROUP BY price_band
ORDER BY total_products DESC;
-- Observation: Most products lie in the Mid-range (Rs 50-199), 2147 products with an average discount of 8.36%.

-- 9. Insight:
-- Which in-stock products have very low availability?
SELECT
    product_id,
    name,
    category,
    available_quantity,
    discounted_selling_price
FROM zepto_cleaned
WHERE out_of_stock = 0
  AND available_quantity <= 2
ORDER BY available_quantity ASC, discounted_selling_price DESC
LIMIT 20;
-- Observation- there are bunch of products with low available quantity.

--  10. Insight:
-- Which premium products are sold without any discount?
SELECT
    name,
    category,
    mrp,
    discounted_selling_price
FROM zepto_cleaned
WHERE discount_percent = 0
  AND mrp >= 500
ORDER BY mrp DESC;
-- Observation: 46 listings (20 distinct products) priced Rs 500 or more have no discount, for example Saffola Gold (Jar) in Cooking Essentials.
-- 11, Insight:
-- Which products have the highest price per gram?
SELECT
    name,
    category,
    weight_in_gms,
    discounted_selling_price,
    ROUND(discounted_selling_price / NULLIF(weight_in_gms, 0), 4) AS price_per_gram
FROM zepto_cleaned
WHERE weight_in_gms IS NOT NULL
  AND weight_in_gms > 0
ORDER BY price_per_gram DESC
LIMIT 10;
-- Observation: Everest Saffron Kesar has the highest price per gram at Rs 120.

-- 12.Insight:
--  Do discounted products have better availability than non-discounted products?
SELECT
    CASE
        WHEN discount_percent = 0 THEN 'No Discount'
        ELSE 'Discounted'
    END AS discount_type,
    COUNT(*) AS total_products,
    SUM(out_of_stock) AS out_of_stock_products,
    ROUND(AVG(out_of_stock) * 100, 2) AS out_of_stock_pct,
    ROUND(AVG(available_quantity), 2) AS avg_available_quantity
FROM zepto_cleaned
GROUP BY discount_type;
-- Observation:discounts are associated with better stock availability.



