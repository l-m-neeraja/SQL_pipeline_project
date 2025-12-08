-- Q1: Total number of users
SELECT COUNT(*) AS total_users
FROM users;

-- Q2: Total number of orders and total revenue
SELECT COUNT(*) AS total_orders,
       SUM(total_amount) AS total_revenue
FROM orders;

-- Q3: Orders by status (aggregation)
SELECT status,
       COUNT(*) AS num_orders,
       SUM(total_amount) AS total_revenue
FROM orders
GROUP BY status
ORDER BY num_orders DESC;

-- Q4: Monthly revenue trend
SELECT DATE_TRUNC('month', order_date) AS month,
       COUNT(*) AS num_orders,
       SUM(total_amount) AS total_revenue
FROM orders
GROUP BY month
ORDER BY month;

-- Q5: Revenue by country (join users + orders)
SELECT u.country,
       COUNT(o.order_id) AS num_orders,
       SUM(o.total_amount) AS total_revenue
FROM orders o
JOIN users u ON o.user_id = u.user_id
GROUP BY u.country
ORDER BY total_revenue DESC;

-- Q6: Top 10 users by total spend
SELECT u.user_id,
       u.first_name,
       u.last_name,
       SUM(o.total_amount) AS total_spent
FROM orders o
JOIN users u ON o.user_id = u.user_id
GROUP BY u.user_id, u.first_name, u.last_name
ORDER BY total_spent DESC
LIMIT 10;

-- Q7: Top 10 products by revenue (join orders + order_items + products)
SELECT p.product_id,
       p.product_name,
       p.category,
       SUM(oi.line_amount) AS product_revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status = 'delivered'
GROUP BY p.product_id, p.product_name, p.category
ORDER BY product_revenue DESC
LIMIT 10;

-- Q8: Average order value (AOV) overall and by payment_method
SELECT payment_method,
       COUNT(*) AS num_orders,
       SUM(total_amount) AS total_revenue,
       AVG(total_amount) AS avg_order_value
FROM orders
GROUP BY payment_method
ORDER BY avg_order_value DESC;

-- Q9: User signup cohort vs number of orders
SELECT DATE_TRUNC('month', u.signup_date) AS signup_month,
       COUNT(DISTINCT u.user_id) AS users_in_cohort,
       COUNT(o.order_id) AS orders_from_cohort
FROM users u
LEFT JOIN orders o ON u.user_id = o.user_id
GROUP BY signup_month
ORDER BY signup_month;

-- Q10: Percentage of marketing_opt_in users by country
SELECT country,
       AVG(CASE WHEN marketing_opt_in THEN 1 ELSE 0 END) * 100 AS marketing_opt_in_pct
FROM users
GROUP BY country
ORDER BY marketing_opt_in_pct DESC;

-- Q11: Average discount given by category (join with products)
SELECT p.category,
       AVG(oi.discount_pct) AS avg_discount_pct
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY avg_discount_pct DESC;

-- Q12: Orders with more than 3 items (using aggregation)
SELECT oi.order_id,
       COUNT(*) AS num_items,
       SUM(oi.line_amount) AS order_value
FROM order_items oi
GROUP BY oi.order_id
HAVING COUNT(*) > 3
ORDER BY order_value DESC;

-- Q13: First order date per user (window function ROW_NUMBER)
SELECT user_id,
       order_id,
       order_date
FROM (
    SELECT o.*,
           ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY order_date) AS rn
    FROM orders o
) t
WHERE rn = 1;

-- Q14: Recency of users (days since last order) using window + CTE
WITH last_order AS (
    SELECT user_id,
           MAX(order_date) AS last_order_date
    FROM orders
    GROUP BY user_id
)
SELECT u.user_id,
       u.first_name,
       u.last_name,
       last_order_date,
       DATE_DIFF('day', last_order_date, CURRENT_TIMESTAMP) AS days_since_last_order
FROM users u
LEFT JOIN last_order lo ON u.user_id = lo.user_id
ORDER BY days_since_last_order DESC NULLS LAST
LIMIT 50;

-- Q15: Running total of revenue by day (window)
WITH daily_revenue AS (
    SELECT DATE(order_date) AS order_day,
           SUM(total_amount) AS revenue
    FROM orders
    GROUP BY order_day
)
SELECT order_day,
       revenue,
       SUM(revenue) OVER (ORDER BY order_day) AS running_revenue
FROM daily_revenue
ORDER BY order_day;

-- Q16: Rank users by total spend within each country (RANK window)
WITH user_spend AS (
    SELECT u.country,
           u.user_id,
           u.first_name,
           u.last_name,
           SUM(o.total_amount) AS total_spent
    FROM users u
    JOIN orders o ON u.user_id = o.user_id
    GROUP BY u.country, u.user_id, u.first_name, u.last_name
)
SELECT *,
       RANK() OVER (PARTITION BY country ORDER BY total_spent DESC) AS spend_rank_in_country
FROM user_spend
ORDER BY country, spend_rank_in_country
LIMIT 100;

-- Q17: Week-over-week revenue with LAG
WITH weekly AS (
    SELECT DATE_TRUNC('week', order_date) AS week_start,
           SUM(total_amount) AS revenue
    FROM orders
    GROUP BY week_start
)
SELECT week_start,
       revenue,
       LAG(revenue) OVER (ORDER BY week_start) AS prev_week_revenue,
       (revenue - LAG(revenue) OVER (ORDER BY week_start)) AS wow_change,
       CASE 
           WHEN LAG(revenue) OVER (ORDER BY week_start) IS NULL THEN NULL
           ELSE (revenue - LAG(revenue) OVER (ORDER BY week_start))
                / LAG(revenue) OVER (ORDER BY week_start) * 100
       END AS wow_pct_change
FROM weekly
ORDER BY week_start;

-- Q18: Average time to payment after order (join + window function)
SELECT o.order_id,
       o.order_date,
       p.payment_date,
       DATE_DIFF('hour', o.order_date, p.payment_date) AS hours_to_payment
FROM orders o
JOIN payments p ON o.order_id = p.order_id
WHERE p.payment_status = 'paid'
ORDER BY hours_to_payment DESC
LIMIT 100;

-- Q19: Top cities by revenue (join + aggregation)
SELECT shipping_country,
       shipping_city,
       SUM(total_amount) AS total_revenue,
       COUNT(*) AS num_orders
FROM orders
GROUP BY shipping_country, shipping_city
ORDER BY total_revenue DESC
LIMIT 20;

-- Q20: Users with more than 5 orders (subquery in HAVING)
SELECT u.user_id,
       u.first_name,
       u.last_name,
       COUNT(o.order_id) AS num_orders
FROM users u
JOIN orders o ON u.user_id = o.user_id
GROUP BY u.user_id, u.first_name, u.last_name
HAVING COUNT(o.order_id) > 5
ORDER BY num_orders DESC;

-- Q21: Orders with value above average (scalar subquery)
SELECT o.*
FROM orders o
WHERE o.total_amount > (SELECT AVG(total_amount) FROM orders)
ORDER BY o.total_amount DESC
LIMIT 100;

-- Q22: Category share of revenue (CTE + aggregation)
WITH category_revenue AS (
    SELECT p.category,
           SUM(oi.line_amount) AS revenue
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.status = 'delivered'
    GROUP BY p.category
)
SELECT category,
       revenue,
       revenue / SUM(revenue) OVER () * 100 AS revenue_share_pct
FROM category_revenue
ORDER BY revenue DESC;

-- Q23: User lifetime value (LTV) approximation (CTE + aggregation)
WITH user_ltv AS (
    SELECT user_id,
           SUM(total_amount) AS total_spent,
           COUNT(*) AS num_orders,
           MIN(order_date) AS first_order,
           MAX(order_date) AS last_order
    FROM orders
    GROUP BY user_id
)
SELECT u.user_id,
       u.first_name,
       u.last_name,
       total_spent,
       num_orders,
       DATE_DIFF('day', first_order, last_order) AS active_days
FROM users u
JOIN user_ltv l ON u.user_id = l.user_id
ORDER BY total_spent DESC
LIMIT 50;

-- Q24: Most frequently bought-together products (self join on order_items)
WITH pairs AS (
    SELECT oi1.product_id AS product_a,
           oi2.product_id AS product_b,
           COUNT(DISTINCT oi1.order_id) AS orders_together
    FROM order_items oi1
    JOIN order_items oi2
      ON oi1.order_id = oi2.order_id
     AND oi1.product_id < oi2.product_id
    GROUP BY oi1.product_id, oi2.product_id
)
SELECT p1.product_name AS product_a,
       p2.product_name AS product_b,
       orders_together
FROM pairs
JOIN products p1 ON pairs.product_a = p1.product_id
JOIN products p2 ON pairs.product_b = p2.product_id
ORDER BY orders_together DESC
LIMIT 20;

-- Q25: Rolling 7-day revenue (window frame)
WITH daily AS (
    SELECT DATE(order_date) AS day,
           SUM(total_amount) AS revenue
    FROM orders
    GROUP BY day
)
SELECT day,
       revenue,
       SUM(revenue) OVER (
           ORDER BY day
           ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
       ) AS rolling_7d_revenue
FROM daily
ORDER BY day;

-- Q26: Refund rate by payment method (join + aggregation)
SELECT o.payment_method,
       COUNT(*) AS num_orders,
       SUM(CASE WHEN p.payment_status = 'refunded' THEN 1 ELSE 0 END) AS num_refunded,
       SUM(CASE WHEN p.payment_status = 'refunded' THEN 1 ELSE 0 END) * 100.0
       / COUNT(*) AS refund_rate_pct
FROM orders o
JOIN payments p ON o.order_id = p.order_id
GROUP BY o.payment_method
ORDER BY refund_rate_pct DESC;

-- Q27: Users with no orders (LEFT JOIN + WHERE NULL)
SELECT u.*
FROM users u
LEFT JOIN orders o ON u.user_id = o.user_id
WHERE o.order_id IS NULL
ORDER BY u.signup_date
LIMIT 100;

-- Q28: Most active users in last 30 days (filter + join)
WITH recent_orders AS (
    SELECT *
    FROM orders
    WHERE order_date >= DATEADD('day', -30, CURRENT_TIMESTAMP)
)
SELECT u.user_id,
       u.first_name,
       u.last_name,
       COUNT(ro.order_id) AS recent_orders,
       SUM(ro.total_amount) AS recent_revenue
FROM recent_orders ro
JOIN users u ON ro.user_id = u.user_id
GROUP BY u.user_id, u.first_name, u.last_name
ORDER BY recent_orders DESC
LIMIT 20;

-- Q29: Median order value by payment method (window + percentile_cont)
SELECT DISTINCT
    payment_method,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_amount)
        OVER (PARTITION BY payment_method) AS median_order_value
FROM orders
ORDER BY median_order_value DESC;

-- Q30: Distribution of order sizes (#items per order)
WITH order_item_counts AS (
    SELECT order_id,
           COUNT(*) AS num_items
    FROM order_items
    GROUP BY order_id
)
SELECT num_items,
       COUNT(*) AS num_orders
FROM order_item_counts
GROUP BY num_items
ORDER BY num_items;

-- Q31: Category revenue by month (multi-level aggregation)
WITH order_item_ext AS (
    SELECT o.order_id,
           o.order_date,
           p.category,
           oi.line_amount
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
)
SELECT DATE_TRUNC('month', order_date) AS month,
       category,
       SUM(line_amount) AS revenue
FROM order_item_ext
GROUP BY month, category
ORDER BY month, revenue DESC;

-- Q32: Users whose total spend is above country average (subquery + join)
WITH user_spend AS (
    SELECT u.user_id,
           u.country,
           SUM(o.total_amount) AS total_spent
    FROM users u
    JOIN orders o ON u.user_id = o.user_id
    GROUP BY u.user_id, u.country
),
country_avg AS (
    SELECT country,
           AVG(total_spent) AS avg_spent
    FROM user_spend
    GROUP BY country
)
SELECT us.user_id,
       us.country,
       us.total_spent,
       ca.avg_spent
FROM user_spend us
JOIN country_avg ca ON us.country = ca.country
WHERE us.total_spent > ca.avg_spent
ORDER BY us.country, us.total_spent DESC;

-- Q33: Time between first and second order (window LAG)
WITH user_orders AS (
    SELECT user_id,
           order_id,
           order_date,
           ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY order_date) AS rn
    FROM orders
)
SELECT user_id,
       MAX(CASE WHEN rn = 1 THEN order_date END) AS first_order_date,
       MAX(CASE WHEN rn = 2 THEN order_date END) AS second_order_date,
       DATE_DIFF(
           'day',
           MAX(CASE WHEN rn = 1 THEN order_date END),
           MAX(CASE WHEN rn = 2 THEN order_date END)
       ) AS days_between
FROM user_orders
WHERE rn <= 2
GROUP BY user_id
HAVING COUNT(*) = 2
ORDER BY days_between;

-- Q34: Active vs inactive products (by revenue)
WITH product_revenue AS (
    SELECT p.product_id,
           p.is_active,
           SUM(oi.line_amount) AS revenue
    FROM products p
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    GROUP BY p.product_id, p.is_active
)
SELECT is_active,
       COUNT(*) AS num_products,
       SUM(revenue) AS total_revenue
FROM product_revenue
GROUP BY is_active;

-- Q35: Orders with failed payment (join + filter)
SELECT o.order_id,
       o.user_id,
       o.total_amount,
       p.payment_status
FROM orders o
JOIN payments p ON o.order_id = p.order_id
WHERE p.payment_status = 'failed'
ORDER BY o.order_date DESC
LIMIT 100;

-- Q36: Customer segmentation by total spend (window + CASE)
WITH user_spend AS (
    SELECT u.user_id,
           u.first_name,
           u.last_name,
           SUM(o.total_amount) AS total_spent
    FROM users u
    LEFT JOIN orders o ON u.user_id = o.user_id
    GROUP BY u.user_id, u.first_name, u.last_name
)
SELECT user_id,
       first_name,
       last_name,
       total_spent,
       CASE
           WHEN total_spent IS NULL OR total_spent = 0 THEN 'No spend'
           WHEN total_spent < 100 THEN 'Low value'
           WHEN total_spent < 500 THEN 'Medium value'
           ELSE 'High value'
       END AS segment
FROM user_spend
ORDER BY total_spent DESC NULLS LAST;

-- Q37: Country-wise ARPU (Average Revenue Per User)
WITH user_spend AS (
    SELECT u.user_id,
           u.country,
           COALESCE(SUM(o.total_amount), 0) AS total_spent
    FROM users u
    LEFT JOIN orders o ON u.user_id = o.user_id
    GROUP BY u.user_id, u.country
)
SELECT country,
       AVG(total_spent) AS arpu
FROM user_spend
GROUP BY country
ORDER BY arpu DESC;

-- Q38: Users ordering in multiple categories (subquery with COUNT DISTINCT)
WITH user_categories AS (
    SELECT o.user_id,
           COUNT(DISTINCT p.category) AS distinct_categories
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY o.user_id
)
SELECT u.user_id,
       u.first_name,
       u.last_name,
       distinct_categories
FROM user_categories uc
JOIN users u ON uc.user_id = u.user_id
WHERE distinct_categories >= 3
ORDER BY distinct_categories DESC;

-- Q39: Products with no sales (LEFT JOIN + NULL check)
SELECT p.*
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
WHERE oi.product_id IS NULL
ORDER BY p.created_at
LIMIT 100;

-- Q40: Average order frequency per user (orders per active month)
WITH user_orders AS (
    SELECT user_id,
           MIN(order_date) AS first_order,
           MAX(order_date) AS last_order,
           COUNT(*) AS num_orders
    FROM orders
    GROUP BY user_id
)
SELECT uo.user_id,
       uo.num_orders,
       DATE_DIFF('month', uo.first_order, uo.last_order) + 1 AS active_months,
       uo.num_orders
       / (DATE_DIFF('month', uo.first_order, uo.last_order) + 1) AS orders_per_month
FROM user_orders uo
ORDER BY orders_per_month DESC
LIMIT 50;

-- Q41: Orders per signup cohort (CTE using subquery)
WITH cohort AS (
    SELECT u.user_id,
           DATE_TRUNC('month', signup_date) AS signup_month
    FROM users u
)
SELECT c.signup_month,
       COUNT(DISTINCT c.user_id) AS users_in_cohort,
       COUNT(o.order_id) AS orders_in_cohort
FROM cohort c
LEFT JOIN orders o ON c.user_id = o.user_id
GROUP BY c.signup_month
ORDER BY c.signup_month;

-- Q42: Top 10% users by spend (window + NTILE)
WITH user_spend AS (
    SELECT u.user_id,
           u.first_name,
           u.last_name,
           COALESCE(SUM(o.total_amount), 0) AS total_spent
    FROM users u
    LEFT JOIN orders o ON u.user_id = o.user_id
    GROUP BY u.user_id, u.first_name, u.last_name
),
with_deciles AS (
    SELECT *,
           NTILE(10) OVER (ORDER BY total_spent DESC) AS spend_decile
    FROM user_spend
)
SELECT *
FROM with_deciles
WHERE spend_decile = 1
ORDER BY total_spent DESC;

-- Q43: Hour-of-day order distribution
SELECT EXTRACT(hour FROM order_date) AS order_hour,
       COUNT(*) AS num_orders,
       SUM(total_amount) AS revenue
FROM orders
GROUP BY order_hour
ORDER BY order_hour;

-- Q44: Category-month matrix with window share (window over partition)
WITH cat_month AS (
    SELECT DATE_TRUNC('month', o.order_date) AS month,
           p.category,
           SUM(oi.line_amount) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY month, p.category
)
SELECT month,
       category,
       revenue,
       revenue * 100.0 / SUM(revenue) OVER (PARTITION BY month) AS cat_share_in_month_pct
FROM cat_month
ORDER BY month, revenue DESC;

-- Q45: Repeat purchase rate (users with 2+ orders)
WITH user_order_counts AS (
    SELECT user_id,
           COUNT(*) AS num_orders
    FROM orders
    GROUP BY user_id
)
SELECT
    SUM(CASE WHEN num_orders >= 2 THEN 1 ELSE 0 END) * 100.0
    / COUNT(*) AS repeat_purchase_rate_pct
FROM user_order_counts;

-- Q46: Average discount used per user
WITH user_discount AS (
    SELECT o.user_id,
           AVG(oi.discount_pct) AS avg_discount_pct
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.user_id
)
SELECT u.user_id,
       u.first_name,
       u.last_name,
       avg_discount_pct
FROM user_discount ud
JOIN users u ON ud.user_id = u.user_id
ORDER BY avg_discount_pct DESC
LIMIT 50;

-- Q47: Orders where total_amount differs from sum of line_amounts (data quality check)
WITH order_line_sum AS (
    SELECT oi.order_id,
           SUM(oi.line_amount) AS line_sum
    FROM order_items oi
    GROUP BY oi.order_id
)
SELECT o.order_id,
       o.total_amount,
       ols.line_sum,
       (o.total_amount - ols.line_sum) AS diff
FROM orders o
JOIN order_line_sum ols ON o.order_id = ols.order_id
WHERE ABS(o.total_amount - ols.line_sum) > 0.01
ORDER BY ABS(o.total_amount - ols.line_sum) DESC
LIMIT 100;

-- Q48: Order funnel by status (FULL OUTER/LEFT-ish analysis)
SELECT status,
       COUNT(*) AS num_orders,
       SUM(total_amount) AS total_revenue
FROM orders
GROUP BY status
ORDER BY num_orders DESC;

-- Q49: Country x payment_method revenue matrix
SELECT u.country,
       o.payment_method,
       SUM(o.total_amount) AS revenue
FROM orders o
JOIN users u ON o.user_id = u.user_id
GROUP BY u.country, o.payment_method
ORDER BY u.country, revenue DESC;

-- Q50: Top 5 categories for each country by revenue (window DENSE_RANK)
WITH country_category AS (
    SELECT u.country,
           p.category,
           SUM(oi.line_amount) AS revenue
    FROM orders o
    JOIN users u ON o.user_id = u.user_id
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY u.country, p.category
),
ranked AS (
    SELECT *,
           DENSE_RANK() OVER (PARTITION BY country ORDER BY revenue DESC) AS category_rank
    FROM country_category
)
SELECT country,
       category,
       revenue,
       category_rank
FROM ranked
WHERE category_rank <= 5
ORDER BY country, category_rank;
