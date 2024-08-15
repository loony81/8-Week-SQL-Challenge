/*==========================
Case Study #1 - Danny's Diner
============================*/

-- 1. What is the total amount each customer spent at the restaurant?
SELECT customer_id, SUM(price) AS total_spent
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY customer_id

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date)
FROM sales 
GROUP BY customer_id

-- 3. What was the first item from the menu purchased by each customer?

SELECT customer_id, order_date, product_name FROM
(
SELECT customer_id, order_date, product_id,
       ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date) row_number
FROM sales
) sq
JOIN menu ON sq.product_id = menu.product_id
WHERE row_number = 1

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT customer_id, count(customer_id) FROM sales
WHERE product_id = (
    SELECT product_id FROM (
        -- This subquery by itself finds the most purchased item
        SELECT product_id, COUNT(*) FROM sales
        GROUP BY product_id 
        LIMIT 1
    ) sq
)
GROUP BY customer_id

-- 5. Which item was the most popular for each customer?
SELECT customer_id, product_name, how_many FROM (
    SELECT customer_id, product_name, COUNT(*) AS how_many,
    RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(*) DESC) ranking
    FROM sales s
    JOIN menu m ON s.product_id = m.product_id
    GROUP BY customer_id, product_name
    ORDER BY customer_id, how_many DESC
) sq
WHERE ranking = 1

-- 6. Which item was purchased first by the customer after they became a member?
SELECT customer_id, order_date, product_name FROM (
    SELECT s.customer_id, order_date, product_name,
    ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY order_date) AS row_number
    FROM sales s
    JOIN members mb on s.customer_id = mb.customer_id
    JOIN menu m ON s.product_id = m.product_id
    WHERE order_date > join_date
) sq
 WHERE row_number = 1

 --7. Which item was purchased just before the customer bacame a member?
SELECT customer_id, order_date, product_name FROM (
    SELECT s.customer_id, order_date, product_name,
    DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY order_date DESC) AS row_number
    FROM sales s
    JOIN members mb on s.customer_id = mb.customer_id
    JOIN menu m ON s.product_id = m.product_id
    WHERE order_date < join_date
) sq
WHERE row_number = 1

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, COUNT(*) as items_number, SUM(price) AS amount_spent
FROM sales s
JOIN members mb on s.customer_id = mb.customer_id
JOIN menu m ON s.product_id = m.product_id
WHERE order_date < join_date
GROUP BY s.customer_id

-- 9. If each $1 spent equates to 10 points and sushi has a x2 points multiplier - how many points would each customer have?
SELECT customer_id, SUM(points) AS total_points FROM (
    SELECT customer_id, price, product_name,
    CASE WHEN product_name = 'sushi' THEN price*20
    ELSE price*10
    END AS points
    FROM sales s
    JOIN menu m ON s.product_id = m.product_id
) sq
GROUP BY customer_id
ORDER BY customer_id

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
-- not just sushi - how many points do customer A and B have at the end of January?
SELECT customer_id, SUM(points) AS total_points FROM (
    SELECT s.customer_id, price, product_name, order_date,
    CASE WHEN order_date BETWEEN join_date AND (join_date + INTERVAL '7 day') THEN price*20
    ELSE price*10
    END AS points
    FROM sales s
    JOIN menu m ON s.product_id = m.product_id
    JOIN members mb on s.customer_id = mb.customer_id
    WHERE order_date < '2021-02-01'
) sq
GROUP BY customer_id

-- Bonus Questions
-- 11. Join All The Things
SELECT s.customer_id, order_date, product_name, price,
CASE WHEN join_date IS NULL THEN 'N'
WHEN order_date < join_date THEN 'N'
ELSE 'Y'
END AS member
FROM sales s 
JOIN menu m 
ON s.product_id = m.product_id
LEFT JOIN members mb ON s.customer_id = mb.customer_id
ORDER BY customer_id, order_date

-- 12. Rank All The Things
WITH cte AS (
    SELECT s.customer_id, order_date, product_name, price,
    CASE WHEN join_date IS NULL THEN 'N'
    WHEN order_date < join_date THEN 'N'
    ELSE 'Y'
    END AS member
    FROM sales s 
    JOIN menu m 
    ON s.product_id = m.product_id
    LEFT JOIN members mb ON s.customer_id = mb.customer_id
)

SELECT *,
CASE WHEN member = 'N' THEN NULL
ELSE RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date)
END AS ranking
FROM cte