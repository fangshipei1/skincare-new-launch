/* Rename table to save typing at later stage*/
EXEC sp_rename 'Sephora skincare product','Products';

/* Create a primary key*/ 
ALTER TABLE Products
ADD id INT IDENTITY(1,1) PRIMARY KEY;

SELECT TOP 5 * FROM Products; -- verify id column 

/* Sanity Check */
Select 
	count(id) as total_products,
	SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) as price_nulls,
	SUM(CASE WHEN rating IS NULL THEN 1 ELSE 0 END) as rating_nulls,
	SUM(CASE WHEN ingredients IS NULL THEN 1 ELSE 0 END) as ngredient_nulls,
	SUM(CASE WHEN brand IS NULL THEN 1 ELSE 0 END) as brand_nulls
From Products

/*categories comparison_market opportunity*/
SELECT 
	type, 
	COUNT(name) as product_count,
	COUNT (distinct brand) as brand_count,
	CAST(COUNT(name)*1.0 / COUNT (distinct brand)as decimal(1,0)) as avg_product_per_brand,
	SUM(CASE WHEN Combination = 1 THEN 1 ELSE 0 END) as Combination_count,
	SUM(CASE WHEN Dry = 1 THEN 1 ELSE 0 END) as Dry_count,
    SUM(CASE WHEN Oily = 1 THEN 1 ELSE 0 END) as Oily_count,
    SUM(CASE WHEN Sensitive = 1 THEN 1 ELSE 0 END) as Sensitive_count,
	CAST(AVG(rating) as decimal(2,1)) as avg_rating,
	CAST(AVG(price) as decimal(6,2)) as avg_price
FROM 
	Products
GROUP BY
	type
ORDER BY 
	product_count DESC

/* The Efficiency Gap: Price vs Rating for all categories*/
WITH segment_average as 
(SELECT
	type,
	price,
	rating,
	name,
	CAST(AVG((price)*1.0) OVER (PARTITION BY type)as decimal (6,2)) as avg_price
FROM
	Products)
SELECT 
	CASE 
		WHEN price < 0.8*avg_price THEN 'Budget' 
		WHEN price >= 0.8*avg_price AND price < 1.2*avg_price THEN 'Premium'
		ELSE 'Luxury'
	END as price_segment,
	COUNT(name) as total_products,
	CAST(AVG(rating)as decimal (3,2)) as averge_rating,
	CAST(AVG(price)as decimal (6,2)) as averge_price
FROM
	segment_average
GROUP BY 
	CASE 
		WHEN price < 0.8*avg_price THEN 'Budget' 
		WHEN price >= 0.8*avg_price AND price < 1.2*avg_price THEN 'Premium'
		ELSE 'Luxury'
	END
ORDER BY 
	averge_rating DESC 

/*Price vs Rating: Eye cream sector only*/
WITH segment_average as 
(SELECT
	type,
	price,
	rating,
	name,
	CAST(AVG((price)*1.0) OVER (PARTITION BY type)as decimal (6,2)) as avg_price
FROM
	Products)
SELECT 
	CASE 
		WHEN price < 0.8*avg_price THEN 'Budget' 
		WHEN price >= 0.8*avg_price AND price < 1.2*avg_price THEN 'Premium'
		ELSE 'Luxury'
	END as price_segment,
	COUNT(name) as total_products,
	CAST(AVG(rating)as decimal (3,2)) as averge_rating,
	CAST(AVG(price)as decimal (6,2)) as averge_price
FROM
	segment_average
WHERE 
	type = 'Eye cream'
GROUP BY 
	CASE 
		WHEN price < 0.8*avg_price THEN 'Budget' 
		WHEN price >= 0.8*avg_price AND price < 1.2*avg_price THEN 'Premium'
		ELSE 'Luxury'
	END
ORDER BY 
	averge_rating DESC 

/*Price vs Rating: Treatment sector only*/
WITH segment_average as 
(SELECT
	type,
	price,
	rating,
	name,
	CAST(AVG((price)*1.0) OVER (PARTITION BY type)as decimal (6,2)) as avg_price
FROM
	Products)
SELECT 
	CASE 
		WHEN price < 0.8*avg_price THEN 'Budget' 
		WHEN price >= 0.8*avg_price AND price < 1.2*avg_price THEN 'Premium'
		ELSE 'Luxury'
	END as price_segment,
	COUNT(name) as total_products,
	CAST(AVG(rating)as decimal (3,2)) as averge_rating,
	CAST(AVG(price)as decimal (6,2)) as averge_price
FROM
	segment_average
WHERE 
	type = 'Treatment'
GROUP BY 
	CASE 
		WHEN price < 0.8*avg_price THEN 'Budget' 
		WHEN price >= 0.8*avg_price AND price < 1.2*avg_price THEN 'Premium'
		ELSE 'Luxury'
	END
ORDER BY 
	averge_rating DESC 

/* Hero product in eye creams and treatment sectors*/
WITH segment_average as 
(SELECT*,
	CAST(AVG((price)*1.0) OVER (PARTITION BY type)as decimal (6,2)) as avg_price
FROM
	Products),
ranked_products AS 
(SELECT*,
	DENSE_RANK() OVER (PARTITION BY type ORDER BY rating DESC, price ASC) as rank_category
FROM 
	segment_average
WHERE
	(type = 'Eye cream' OR type = 'Treatment') AND 
	price >= 0.8*avg_price AND price < 1.2*avg_price)
SELECT
	type,
	brand,
	name,
	price,
	rating, 
	Combination,
	Dry,
	Normal,
	Oily,
	Sensitive
FROM
	ranked_products
WHERE
	rank_category <=5
ORDER BY
	rating DESC, price ASC
