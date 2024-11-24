--ДЗ по SQL: Join
--часть 2.1
select
    distinct(p.product_category),
    (select sum(o.order_ammount)
	from "Orders_2" o
     join "Products_2" p2 on o.product_id = p2.product_id
     where p2.product_category = p.product_category) AS total_sales
     --фильтруемся по категории продукта, так что для каждого продукта из внешнего запроса
     --мы вычисляем сумму заказов только для той категории, которая соответствует текущему продукту 
     --из таблицы Products_2
from "Products_2" p
 order by total_sales desc;
--GROUP by p.product_category;
    
-- задание также можно выполнить без подзапроса :)      
select p2.product_category,
		SUM(o.order_ammount) as total_sales
from "Orders_2" o
join "Products_2" p2 ON o.product_id = p2.product_id
group by p2.product_category
order by total_sales desc
---------------------------------------------------------------------------------
--часть 2.2
select product_category,
    sum(o.order_ammount) as total_sales
from "Orders_2" o
join "Products_2" p2 on o.product_id = p2.product_id
group by p2.product_category
having  sum(o.order_ammount) = (
--оставляем только те категории, где сумма продаж равна максимальной
        select 
            max(total_sales)
        from(select sum(o.order_ammount) as total_sales
            from "Orders_2" o
			join "Products_2" p2 on o.product_id = p2.product_id
			group by p2.product_category) as summed_sales);
		--подзапрос находит максимальную сумму продаж среди всех категорий.

--без подзапроса:
SELECT p2.product_category,
		SUM(o.order_ammount) as total_sales
     FROM "Orders_2" o
     JOIN "Products_2" p2 ON o.product_id = p2.product_id
     GROUP by p2.product_category
     order by total_sales desc
limit 1
---------------------------------------------------------------------------------
--часть 2.3
select  
    p.product_category,
    p.product_name,
    sum(o.order_ammount) as product_sales
from "Orders_2" o
join "Products_2" p on o.product_id = p.product_id
group by p.product_category, p.product_name
having sum(o.order_ammount) = (
        select  
        	max(product_sales)
        from (select 
                sum(o2.order_ammount) as product_sales
              from "Orders_2" o2
            join "Products_2" p2 on o2.product_id = p2.product_id
            where p2.product_category = p.product_category
            group by p2.product_name) as max_sales)
         --подзапрос в HAVING сначала вычисляет для каждой категории продуктов максимальную сумму продаж
		 --внешний запрос выбирает те продукты, чья сумма продаж равна максимальной для своей категории