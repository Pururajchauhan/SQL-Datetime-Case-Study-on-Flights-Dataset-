USE sql_cx_live;

SELECT * FROM laptops;

-- Head
SELECT * FROM laptops
ORDER BY `index`
LIMIT 5;

-- Tail
SELECT * FROM laptops
ORDER BY `index` DESC
LIMIT 5;

-- Random Sample
SELECT * FROM laptops
ORDER BY RAND()
LIMIT 5;

-- Summary Statistics
SELECT COUNT(Price) OVER(),
       MIN(Price) OVER(),
       MAX(Price) OVER(),
       AVG(Price) OVER(),
       STD(Price) OVER(),
       PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Price) OVER() AS Q1,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Price) OVER() AS Median,
       PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Price) OVER() AS Q3
FROM laptops
ORDER BY `index`
LIMIT 1;

-- Missing Values
SELECT COUNT(Price)
FROM laptops
WHERE Price IS NULL;

-- Outliers
SELECT *
FROM (
    SELECT *,
           PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Price) OVER() AS Q1,
           PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Price) OVER() AS Q3
    FROM laptops
) t
WHERE t.Price < t.Q1 - (1.5 * (t.Q3 - t.Q1))
   OR t.Price > t.Q3 + (1.5 * (t.Q3 - t.Q1));

-- Histogram Buckets
SELECT t.buckets,
       REPEAT('*', COUNT(*) / 5)
FROM (
    SELECT price,
           CASE
               WHEN price BETWEEN 0 AND 25000 THEN '0-25K'
               WHEN price BETWEEN 25001 AND 50000 THEN '25K-50K'
               WHEN price BETWEEN 50001 AND 75000 THEN '50K-75K'
               WHEN price BETWEEN 75001 AND 100000 THEN '75K-100K'
               ELSE '>100K'
           END AS buckets
    FROM laptops
) t
GROUP BY t.buckets;

-- Company Counts
SELECT Company, COUNT(Company)
FROM laptops
GROUP BY Company;

-- Numerical Bivariate
SELECT cpu_speed, Price
FROM laptops;

-- Touchscreen Analysis
SELECT Company,
       SUM(CASE WHEN Touchscreen = 1 THEN 1 ELSE 0 END) AS Touchscreen_yes,
       SUM(CASE WHEN Touchscreen = 0 THEN 1 ELSE 0 END) AS Touchscreen_no
FROM laptops
GROUP BY Company;

-- CPU Brands
SELECT DISTINCT cpu_brand
FROM laptops;

SELECT Company,
       SUM(CASE WHEN cpu_brand = 'Intel' THEN 1 ELSE 0 END) AS intel,
       SUM(CASE WHEN cpu_brand = 'AMD' THEN 1 ELSE 0 END) AS amd,
       SUM(CASE WHEN cpu_brand = 'Samsung' THEN 1 ELSE 0 END) AS samsung
FROM laptops
GROUP BY Company;

-- Company-wise Price Stats
SELECT Company,
       MIN(price),
       MAX(price),
       AVG(price),
       STD(price)
FROM laptops
GROUP BY Company;

-- Missing Prices
SELECT *
FROM laptops
WHERE price IS NULL;

-- Fill Missing Prices with Overall Mean
UPDATE laptops
SET price = (SELECT AVG(price) FROM laptops)
WHERE price IS NULL;

-- Fill Missing Prices with Company Mean
UPDATE laptops l1
SET price = (
    SELECT AVG(price)
    FROM laptops l2
    WHERE l2.Company = l1.Company
)
WHERE price IS NULL;

SELECT *
FROM laptops
WHERE price IS NULL;

-- Feature Engineering: PPI
ALTER TABLE laptops
ADD COLUMN ppi INTEGER;

UPDATE laptops
SET ppi = ROUND(
    SQRT(
        resolution_width * resolution_width +
        resolution_height * resolution_height
    ) / Inches
);

SELECT *
FROM laptops
ORDER BY ppi DESC;

-- Screen Size Category
ALTER TABLE laptops
ADD COLUMN screen_size VARCHAR(255) AFTER Inches;

UPDATE laptops
SET screen_size =
CASE
    WHEN Inches < 14.0 THEN 'small'
    WHEN Inches >= 14.0 AND Inches < 17.0 THEN 'medium'
    ELSE 'large'
END;

SELECT screen_size,
       AVG(price)
FROM laptops
GROUP BY screen_size;

-- One Hot Encoding
SELECT gpu_brand,
       CASE WHEN gpu_brand = 'Intel' THEN 1 ELSE 0 END AS intel,
       CASE WHEN gpu_brand = 'AMD' THEN 1 ELSE 0 END AS amd,
       CASE WHEN gpu_brand = 'nvidia' THEN 1 ELSE 0 END AS nvidia,
       CASE WHEN gpu_brand = 'arm' THEN 1 ELSE 0 END AS arm
FROM laptops;