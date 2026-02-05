select * from communication_logs

A1.  O2C Connect Rate for WhatsApp
SELECT
    COUNT(CASE 
            WHEN customer_action IN ('Clicked', 'Replied') 
            THEN 1 
         END) * 1.0
    /
    COUNT(CASE 
            WHEN delivery_status = 'Delivered' 
            THEN 1 
         END) AS o2c_connect_rate
FROM communication_logs
WHERE channel = 'WhatsApp';

A1.2    Top 5 Cities with Lowest O2C Connect Rate
select o.city,
 COUNT(CASE 
            WHEN customer_action IN ('Clicked', 'Replied') 
            THEN 1 
         END) * 1.0
    /
    COUNT(CASE 
            WHEN delivery_status = 'Delivered' 
            THEN 1 
         END) AS o2c_connect_rate
FROM communication_logs c
JOIN orders o ON c.order_id = o.order_id
WHERE channel = 'WhatsApp'
GROUP BY o.city
HAVING COUNT(CASE WHEN delivery_status = 'Delivered'  THEN 1 END) > 50
ORDER BY o2c_connect_rate ASC
LIMIT 5;

A2. Customer Purchase Behavior
A2.1 Repeat Purchase Rate by City & Category
Repeat customer = customer with >1 order
WITH customer_orders AS (
  SELECT
    customer_id,
    city,
    product_category,
    COUNT(order_id) AS total_orders
  FROM orders
  GROUP BY customer_id, city, product_category
)

SELECT
  city,
  product_category,
  COUNT(CASE WHEN total_orders > 1 THEN 1 END) * 1.0
  / COUNT(*) AS repeat_purchase_rate
FROM customer_orders
GROUP BY city, product_category;

A2.2 Cohort Table (First Purchase × Repeat Month)
WITH first_purchase AS (
  SELECT
    customer_id,
    MIN(extract(month from order_date)) AS cohort_month
  FROM orders
  GROUP BY customer_id
),
orders_with_cohort AS (
  SELECT
    o.customer_id,
    f.cohort_month,
    extract(month from  o.order_date) AS order_month
  FROM orders o
  JOIN first_purchase f ON o.customer_id = f.customer_id
)
SELECT
  cohort_month,
  order_month,
  COUNT(DISTINCT customer_id) AS customers
FROM orders_with_cohort
GROUP BY cohort_month, order_month
ORDER BY cohort_month, order_month;

A3. Delivery & Supply Chain
A3.1 Promised vs Actual Delivery Gap
SELECT
  order_id,
  actual_delivery_date - promised_delivery_date AS delivery_gap_days
FROM orders;

A3.2 Orders Delayed Due to Courier
SELECT *
FROM supply_chain
WHERE courier_delay_flag = 'True'

A4. Communication Channel Insights
SELECT
  channel,
  COUNT(CASE WHEN delivery_status='Delivered' THEN 1 END) * 1.0 / COUNT(*) AS delivery_rate,
  COUNT(CASE WHEN delivery_status='Read'  THEN 1 END) * 1.0 / COUNT(*) AS read_rate,
  COUNT(CASE WHEN customer_action = 'Clicked' THEN 1 END) * 1.0 / COUNT(*) AS ctr,
  COUNT(CASE WHEN customer_action='Replied' THEN 1 END) * 1.0 / COUNT(*) AS reply_rate
FROM communication_logs
GROUP BY channel;

A5. Support Ticket Analysis
SELECT
  issue_category,
  AVG(resolved_at) AS avg_resolution_time,
  COUNT(CASE WHEN resolution_status =' Escalated'  THEN 1 END) * 1.0 / COUNT(*) AS escalation_rate,
  AVG(csat_score) AS avg_csat,
  COUNT(*) AS ticket_volume
FROM support_tickets
GROUP BY issue_category;

A6. Vet Transfer Analysis
A6.1 Vet Consult Within 72 Hours of Delivery
SELECT
    COUNT(DISTINCT v.order_id) * 1.0 / COUNT(DISTINCT o.order_id) 
        AS vet_within_72hrs_pct
FROM orders o
LEFT JOIN vet_calls v
    ON o.order_id = v.order_id
WHERE v.call_start_time <= o.actual_delivery_date + INTERVAL 72 HOUR;

A6.2 Avg Duration of Successful Vet Transfers
SELECT
  AVG(call_duration_secs) AS avg_successful_call_duration
FROM vet_calls
WHERE vet_transfer_success = 'TRUE';







