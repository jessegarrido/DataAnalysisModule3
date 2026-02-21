USE coffeeshop_db;

-- =========================================================
-- JOINS & RELATIONSHIPS PRACTICE
-- =========================================================

-- Q1) Join products to categories: list product_name, category_name, price.
select p.name, c.name, p.price
from products p
inner join categories c
	on p.category_id = c.category_id;
-- Q2) For each order item, show: order_id, order_datetime, store_name,
--     product_name, quantity, line_total (= quantity * products.price).
--     Sort by order_datetime, then order_id.
select o.order_id, 
	o.order_datetime, 
    s.name as store_name, 
    p.name as product_name,
    oi.quantity,
    oi.quantity * p.price as line_total
from orders o 
left join order_items oi
	on o.order_id = oi.order_id
left join stores s
	on o.store_id  = s.store_id
left join products p
	on oi.product_id = p.product_id
order by order_datetime, order_id;
-- Q3) Customer order history (PAID only):
--     For each order, show customer_name, store_name, order_datetime,
--     order_total (= SUM(quantity * products.price) per order).
select o.order_id, 
	concat(c.first_name, " ", c.last_name) as customer_name, 
    s.name as store_name, 
    o.order_datetime,
    SUM(oi.quantity * p.price) as order_total
from orders o
left join customers c
	on o.customer_id = c.customer_id
left join stores s
	on o.store_id  = s.store_id
left join order_items oi
	on o.order_id = oi.order_id
left join products p
	on oi.product_id = p.product_id
group by order_id;
-- Q4) Left join to find customers who have never placed an order.
--     Return first_name, last_name, city, state.
SELECT 
    c.first_name,
    c.last_name,
    c.city,
    c.state
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE order_id IS NULL;
-- Q5) For each store, list the top-selling product by units (PAID only).
--     Return store_name, product_name, total_units.
--     Hint: Use a window function (ROW_NUMBER PARTITION BY store) or a correlated subquery.
WITH product_totals AS (
    SELECT 
        s.name AS store_name,
        p.name AS product_name,
        SUM(oi.quantity) AS total_units
    FROM stores s
    JOIN orders o ON s.store_id = o.store_id
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    WHERE o.status = 'PAID'
    GROUP BY s.store_id, s.name, p.product_id, p.name
),
ranked_products AS (
    SELECT 
        store_name,
        product_name,
        total_units,
        ROW_NUMBER() OVER (PARTITION BY store_name ORDER BY total_units DESC) AS product_rank
    FROM product_totals
)
SELECT 
    store_name,
    product_name,
    total_units
FROM ranked_products
WHERE product_rank = 1
ORDER BY store_name;
-- Q6) Inventory check: show rows where on_hand < 12 in any store.
--     Return store_name, product_name, on_hand.
SELECT 
    s.name AS store_name,
    p.name AS product_name,
    i.on_hand
FROM inventory i
JOIN stores s ON i.store_id = s.store_id
JOIN products p ON i.product_id = p.product_id
WHERE i.on_hand < 12
ORDER BY s.name, i.on_hand;
-- Q7) Manager roster: list each store's manager_name and hire_date.
--     (Assume title = 'Manager').
SELECT 
    s.name AS store_name,
    concat(e.first_name," ",e.last_name) AS manager_name,
    e.hire_date
FROM stores s
JOIN employees e ON s.store_id = e.store_id
WHERE e.title = 'Manager'
ORDER BY s.name;
-- Q8) Using a subquery/CTE: list products whose total PAID revenue is above
--     the average PAID product revenue. Return product_name, total_revenue.
WITH product_revenue AS (
    SELECT 
        p.name AS product_name,
        SUM(p.price * oi.quantity) AS total_revenue
    FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.status = 'PAID'
    GROUP BY p.product_id, p.name
),
average_revenue AS (
    SELECT AVG(total_revenue) AS avg_revenue
    FROM product_revenue
)
SELECT 
    pr.product_name,
    pr.total_revenue
FROM product_revenue pr
CROSS JOIN average_revenue ar
WHERE pr.total_revenue > ar.avg_revenue
ORDER BY pr.total_revenue DESC;
-- Q9) Churn-ish check: list customers with their last PAID order date.
--     If they have no PAID orders, show NULL.
--     Hint: Put the status filter in the LEFT JOIN's ON clause to preserve non-buyer rows.
SELECT 
    concat(c.first_name, " ",c.last_name) as Customer,
    MAX(o.order_datetime) AS last_paid_order_date
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id 
    AND o.status = 'PAID'
GROUP BY c.customer_id, c.first_name, c.last_name, c.city, c.state
ORDER BY last_paid_order_date DESC;
-- Q10) Product mix report (PAID only):
--     For each store and category, show total units and total revenue (= SUM(quantity * products.price)).
SELECT 
    s.name AS store_name,
    c.name AS category_name,
    SUM(oi.quantity) AS total_units,
    SUM(oi.quantity * p.price) AS total_revenue
FROM stores s
JOIN orders o ON s.store_id = o.store_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
WHERE o.status = 'PAID'
GROUP BY s.store_id, s.name, c.category_id, c.name
ORDER BY s.name, c.name;