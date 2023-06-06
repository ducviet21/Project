--task 1
SELECT 
format_date('%Y%m', PARSE_DATE('%Y%m%d' , date)) as month
 ,sum(totals.visits) as visits ,sum(totals.pageviews) as pageviews , sum(totals.transactions) as transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
  where _table_suffix between '0101' and '0331'
  group by 1
  order by month;
  --task 2
  SELECT distinct trafficSource.source ,
 sum(totals.visits) as visits ,sum(totals.bounces) as bounces ,
 (100.0*(sum(totals.bounces))/(sum(totals.visits)) ) as Bounce_rate
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
  group by 1
  order by visits desc;
  --task 3
  SELECT  
'Month' as time_type,
format_date('%Y%m', PARSE_DATE('%Y%m%d' , date)) as time,
 trafficSource.source,
sum(productRevenue)/1000000 as revenue
 FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`,
UNNEST (hits) hits,
UNNEST (hits.product) product
Where productRevenue is not null
group by 1,2,3
union all
SELECT  
'week' as time_type,
format_date('%Y%u', PARSE_DATE('%Y%m%d' , date)) as time,
 trafficSource.source,
sum(productRevenue)/1000000 as revenue
 FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`,
UNNEST (hits) hits,
UNNEST (hits.product) product
where productRevenue is not null
group by 1,2,3
order by revenue desc;
--task 4
with purchaser as ( 
  select format_date('%Y%m', PARSE_DATE('%Y%m%d' , date)) as month ,
(sum(totals.pageviews)/count(distinct fullVisitorId) )  as i1
 FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
,UNNEST (hits) hits,
UNNEST (hits.product) product
 where _table_suffix between '0601' and '0731'and totals.transactions >=1 and  productRevenue is not null
 group by 1 ) ,
 non_purchaser as (
  select format_date('%Y%m', PARSE_DATE('%Y%m%d' , date)) as month ,
(sum(totals.pageviews)/count (distinct fullVisitorId))  as i2
 FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
,UNNEST (hits) hits,
UNNEST (hits.product) product
 where _table_suffix between '0601' and '0731'and totals.transactions is null and  productRevenue is null
 group by 1 )
Select purchaser.month , 
avg(i1) as avg_pageviews_purchase , avg (i2) as avg_pageviews_non_purchase
from purchaser
Left join non_purchaser 
 on non_purchaser.month  = purchaser.month
 group by 1
 order by 1;
 --task 5
 with cte as( select format_date('%Y%m', PARSE_DATE('%Y%m%d' , date)) as month ,
(sum(totals.transactions)/count(distinct fullVisitorId) )  as i1
 FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
UNNEST (hits) hits,
UNNEST (hits.product) product
 where  totals.transactions >=1 and product.productRevenue is not null
 group by 1)
 select month ,avg(i1) as Avg_total_transactions_per_user
 from cte
 group by 1;
 --task 6
 with cte as(select format_date('%Y%m', PARSE_DATE('%Y%m%d' , date)) as month , 
((sum(totals.productRevenue)/1000000)/sum(totals.visits) )  as i1
 FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
UNNEST (hits) hits,
UNNEST (hits.product) product
 where  totals.transactions is not null and product.productRevenue is not null
 group by 1)
 select month , avg(i1) as avg_revenue_by_user_per_visit
 from cte
 group by 1;
 --task 7
 with buyer_list as(
    SELECT
        distinct fullVisitorId
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
    , UNNEST(hits) AS hits
    , UNNEST(hits.product) as product
    WHERE product.v2ProductName = "YouTube Men's Vintage Henley"
    AND totals.transactions>=1
    AND product.productRevenue is not null)
SELECT
  product.v2ProductName AS other_purchased_products,
  SUM(product.productQuantity) AS quantity
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
, UNNEST(hits) AS hits
, UNNEST(hits.product) as product
JOIN buyer_list using(fullVisitorId)
WHERE product.v2ProductName != "YouTube Men's Vintage Henley"
 and product.productRevenue is not null
GROUP BY other_purchased_products
ORDER BY quantity DESC;
 --task 8
 with cte1 as (select format_date('%Y%m', PARSE_DATE('%Y%m%d' , date)) as month,
count(eCommerceAction.action_type) as num_view
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
UNNEST (hits) hits
where _table_suffix between '0101' and '0331' and
   eCommerceAction.action_type='2'
   group by 1 ),
    cte2 as (select format_date('%Y%m', PARSE_DATE('%Y%m%d' , date)) as month,
count(eCommerceAction.action_type) as num_addtocart
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
UNNEST (hits) hits
where _table_suffix between '0101' and '0331' and
   eCommerceAction.action_type='3'
   group by 1 ),
   cte3 as (select format_date('%Y%m', PARSE_DATE('%Y%m%d' , date)) as month,
count(eCommerceAction.action_type) as num_purchase
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
UNNEST (hits) hits,
UNNEST (hits.product) product
where _table_suffix between '0101' and '0331' and
   eCommerceAction.action_type='6' and product.productRevenue is not null
   group by 1 )
Select cte1.month, num_view , num_addtocart,num_purchase ,
round(100*(num_addtocart/num_view),2) as Add_to_cart_rate , round(100*(num_purchase/num_view),2) as Purchase_rate
from cte1 
left join cte2 on cte1.month = cte2.month
left join cte3 on cte2.month = cte3.month
group by 1,2,3,4
order by 1;
