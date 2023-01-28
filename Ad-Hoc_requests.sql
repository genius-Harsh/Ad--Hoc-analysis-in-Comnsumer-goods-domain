/*1. Provide the list of markets in which customer "Atliq Exclusive" operates its
business in the APAC region.
*/
SELECT DISTINCT market FROM dim_customer 
WHERE customer = 'Atliq Exclusive'
AND region = 'APAC'
--------------------------

/*2. What is the percentage of unique product increase in 2021 vs. 2020? The
final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg */
with table1 (unique_products_2020) as
   (select count(distinct mc.product_code) 
    from  fact_manufacturing_cost mc
    where mc.cost_year = 2020),
   
   table2 (unique_products_2021) as 
   (select count(distinct mc.product_code) 
    from fact_manufacturing_cost mc
    where mc.cost_year = 2021)
select table1.unique_products_2020, table2.unique_products_2021, 
(table2.unique_products_2021 - table1.unique_products_2020)*100/table1.unique_products_2020 as percentage_chg
from table1 
join table2;
-------------------------------------

/*3. Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains
2 fields,
segment
product_count
 */
select count(distinct product_code) as product_count, segment 
From dim_product
group by segment 
order by product_count desc;
------------------------------------

/*4. Follow-up: Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields,
segment
product_count_2020
product_count_2021
difference */
select segment,
sum(case when cost_year = 2020 then 1 else 0 end) as product_count_2020,
sum(case when cost_year = 2021 then 1 else 0 end) as product_count_2021,
sum(case when cost_year = 2021 then 1 else 0 end) -sum(case when cost_year = 2020 then 1 else 0 end) as difference
from dim_product dp right join fact_manufacturing_cost mc on 
dp.product_code = mc.product_code GROUP by segment;

/*OR */

with table1 (segment, product_count_2020)  as
   (select  dp.segment, count(distinct mc.product_code) as product_count_2020 
   from  fact_manufacturing_cost mc
   left join dim_product dp 
   on mc.product_code = dp.product_code
   where mc.cost_year = 2020 
   Group by dp.segment),
   
   table2 (segment, product_count_2021)  as
   (select  dp.segment, count(distinct mc.product_code) as product_count_2021 
   from fact_manufacturing_cost mc
   left join dim_product dp 
   on mc.product_code = dp.product_code
   where mc.cost_year = 2021 
   Group by dp.segment)
select table1.segment,product_count_2020, product_count_2021, product_count_2021 -product_count_2020 as difference 
from table1 
join table2
on table1.segment = table2.segment 
order by difference desc;
---------------------------------------------

/*5. Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,
product_code
product
manufacturing_cost */
select mc.product_code, dp.product, mc.manufacturing_cost
from fact_manufacturing_cost mc 
left join dim_product dp
on mc.product_code = dp.product_code
where mc.manufacturing_cost = (select max(manufacturing_cost) from fact_manufacturing_cost)
or mc.manufacturing_cost = (select min(manufacturing_cost) from fact_manufacturing_cost);
----------------------------------------------

/*6. Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage
 */

select id.customer_code, dc.customer, avg(id.pre_invoice_discount_pct) as average_discount_percentage
from fact_pre_invoice_deductions id
left join dim_customer dc
ON id.customer_code = dc.customer_code
where dc.market = 'India' and id.fiscal_year = 2021
group by id.customer_code, dc.customer
order by avg(id.pre_invoice_discount_pct) desc
limit 5 ;

------------------------------------------

/*7. Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.
The final report contains these columns:
Month
Year
Gross sales Amount
 */
select monthname(ms.date) as Month,  Year(ms.date) as Year, sum(ms.sold_quantity*gp.gross_price) as Gross_sales_Amount
from fact_sales_monthly ms 
left join dim_customer dc 
on ms.customer_code = dc.customer_code
join fact_gross_price gp 
on gp.product_code = ms.product_code
where dc.customer = 'Atliq Exclusive'
and ms.fiscal_year = gp.fiscal_year
group by Month, Year;
-----------------------------------------------

/*8. In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity
 */
select sum(ms.sold_quantity) as total_sold_quantity, quarter(ms.date) as Quarter 
from fact_sales_monthly ms
where year(ms.date) = 2020
group by Quarter
order by total_sold_quantity desc;
-----------------------------------------

/* 9. Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage*/
with  gross_sales_channel (channel, gross_sales_mln) as
     (select dc.channel as channel, sum(ms.sold_quantity*gp.gross_price) as gross_sales_min 
      from fact_sales_monthly ms 
      join dim_customer dc on ms.customer_code = dc.customer_code
      join fact_gross_price gp on gp.product_code = ms.product_code
      and gp.fiscal_year = ms.fiscal_year
      group by dc.channel),
	  total_table (total_gross_sales) as 
      (select sum(gross_sales_mln) as Total_gross_sales 
       from gross_sales_channel)
      
select gross_sales_channel.channel, gross_sales_channel.gross_sales_mln,
        round(gross_sales_channel.gross_sales_mln*100/ total_table.total_gross_sales,2) as percentage
        from gross_sales_channel 
        join total_table
        order by percentage desc;
-----------------------------------------------

/* 10. Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these
fields,
division
product_code
product
total_sold_quantity
rank_order
*/
 select * from
 (select  dp.division, ms.product_code, dp.product, sum(ms.sold_quantity) as total_sold_quantity,
 rank() over(partition by dp.division order by sum(ms.sold_quantity) desc) as rank_order
 from fact_sales_monthly ms
 join dim_product dp
 on ms.product_code = dp.product_code
 group by ms.product_code, dp.division, dp.product) x
 where rank_order < 4;