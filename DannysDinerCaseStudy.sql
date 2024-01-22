--USE dannys_diner
SELECT * FROM members
SELECT * FROM menu
SELECT * FROM sales

-- Q1) What is the total amount each customer spent at the restaurant?
SELECT 
    s.customer_id, 
    CONCAT('$',sum(m.price)) as Total_amount
FROM sales s
JOIN menu m 
on s.product_id = m.product_id
group by s.customer_id

-- Q2)How many days has each customer visited the restaurant?
SELECT 
    customer_id, 
    count(distinct order_date) as Number_of_Days 
FROM sales 
GROUP BY customer_id;

-- Q3)What was the first item from the menu purchased by each customer?
WITH CTE as (
    SELECT 
        s.customer_id, 
        m.product_name,
        s.order_date,
        DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY order_date ASC) as first_value
    FROM sales s 
    JOIN menu m on s.product_id = m.product_id

) 
SELECT customer_id, product_name FROM CTE
where first_value = 1
GROUP BY customer_id, product_name

-- Q4) What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT TOP 1 
    m.product_name,
    COUNT(m.product_name) as most_purchased_item
FROM sales s
JOIN menu m 
on s.product_id = m.product_id
GROUP BY  m.product_name
ORDER BY most_purchased_item DESC

--Q5)Which item was the most popular for each customer?
WITH CTE AS(
    SELECT 
        s.customer_id,
        m.product_name,
        COUNT(m.product_id) as order_count,
        DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.customer_id) DESC) as cnt
    FROM sales s 
    JOIN menu m 
    on s.product_id = m.product_id
    GROUP BY s.customer_id, m.product_name
)
SELECT 
  customer_id, 
  product_name, 
  order_count
FROM CTE 
where cnt = 1
;

--Q6) Which item was purchased first by the customer after they became a member?
WITH CTE AS(
    SELECT 
        mem.customer_id, 
        mem.join_date, 
        m.product_name,
        s.order_date,
        ROW_NUMBER() OVER(PARTITION BY mem.customer_id ORDER BY mem.join_date ASC) as row_num
    FROM  members mem
    JOIN sales s 
    on mem.customer_id = s.customer_id
    JOIN menu m 
    on s.product_id = m.product_id
    WHERE s.order_date > mem.join_date
)
SELECT
    customer_id, 
    product_name,
    join_date,
    order_date
FROM CTE
where row_num = 1

--Q7) Which item was purchased just before the customer became a member?
WITH CTE AS(
    SELECT
        mem.customer_id,
        mem.join_date,
        s.order_date,
        m.product_name,
        ROW_NUMBER() OVER(PARTITION BY mem.customer_id ORDER BY s.order_date DESC) as row_num
    FROM members mem
    join sales s 
    on mem.customer_id = s.customer_id
    JOIN menu m 
    on s.product_id = m.product_id
    WHERE s.order_date < mem.join_date
)
SELECT customer_id, product_name FROM CTE
WHERE row_num = 1


-- Q8) What is the total items and amount spent for each member before they became a member?

SELECT 
    s.customer_id,
    count(s.product_id) as total_items,
    CONCAT('$',SUM(m.price)) as Total_amount
FROM sales s 
JOIN menu m 
on s.product_id = m.product_id
JOIN members mem 
on s.customer_id = mem.customer_id
WHERE s.order_date < mem.join_date
GROUP BY s.customer_id;

-- Q9) If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH CTE AS(
    SELECT 
        s.customer_id,
        (CASE 
            WHEN m.product_name = 'sushi' THEN m.price * 20
            ELSE m.price * 10
        END) as case_when
    FROM sales s 
    JOIN menu m 
    on s.product_id = m.product_id
)
SELECT 
    customer_id,
    sum(case_when) as total_points
FROM CTE
GROUP BY customer_id;


-- Q10) In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi
-- how many points do customer A and B have at the end of January?

WITH dates_cte as (
    SELECT *,
    DATEADD(DAY, 6, join_date) as valid_date,
    EOMONTH('2021-01-31') as last_date
    FROM members
)
SELECT 
    m.customer_id,
    SUM(
        CASE 
            WHEN mm.product_id = 1 THEN mm.price * 2 * 10
            WHEN s.order_date BETWEEN m.join_date and m.valid_date THEN mm.price * 2 * 10
        ELSE mm.price * 10
        END
    ) as total_points

from dates_cte m
JOIN sales s 
on m.customer_id = s.customer_id
JOIN menu mm
on s.product_id = mm.product_id
WHERE s.order_date < m.last_date 
GROUP BY  
    m.customer_id;


-- BONUS Question
--Q1
SELECT 
    s.customer_id,
    s.order_date,
    m.product_name,
    m.price,
    (CASE
        WHEN mem.join_date > s.order_date THEN 'N'
        WHEN mem.join_date < = s.order_date THEN 'Y'
        ELSE 'N' 
    END) as 'member'
FROM sales s
LEFT JOIN members mem on s.customer_id = mem.customer_id
JOIN menu m on s.product_id = m.product_id

--Q2
WITH CTE AS(
    SELECT 
        s.customer_id,
        s.order_date,
        m.product_name,
        m.price,
        (CASE
            WHEN mem.join_date > s.order_date THEN 'N'
            WHEN mem.join_date < = s.order_date THEN 'Y'
            ELSE 'N'
        END) as 'member'
    FROM sales s
    LEFT JOIN members mem on mem.customer_id = s.customer_id
    JOIN menu m on s.product_id = m.product_id
)
SELECT
    customer_id,
    order_date, 
    product_name,
    price, 
    member,
    (CASE
        WHEN member = 'N' THEN NULL
        ELSE RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date) 
    END ) as ranking
FROM CTE


