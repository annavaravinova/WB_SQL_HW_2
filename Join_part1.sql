--ДЗ по SQL: Join
--Часть 1.1    
with customer_wait_times as(
    select 
    	o.customer_id,
        c.name,
        extract(epoch from(o.shipment_date::timestamp - o.order_date::timestamp)) as waiting_time
        --разница между доставкой и заказом в секундах, однако в данном датасете роли не играет, так как даты различаются, а время нет
    from orders o
    join customers c on o.customer_id = c.customer_id),
   		-- where o.order_status = 'Approved'
        --также не будем ставить условие на статус заказа,
        --так как считается, что если есть дата доставки, но статус "отменен", значит заказ доставлен, но клиент отказался
max_waiting_time as (
    select 
    	max(waiting_time) as max_time
    from customer_wait_times)
select 
    cwt.customer_id,
    cwt.name,
    cwt.waiting_time as max_waiting_time
from 
    customer_wait_times cwt
join  
    max_waiting_time mwt on cwt.waiting_time = mwt.max_time
--------------------------------------------------------------------------------------------------------------------------
--Часть 1.2
 with customer_order_data as (
    select 
        o.customer_id,
        c.name,
        count(o.order_id) as total_orders,
        --avg(date_part('day', o.shipment_date::timestamp - o.order_date::timestamp)) as avg_delivery_time,
        avg(o.shipment_date::timestamp - o.order_date::timestamp) as avg_delivery_time,
        SUM(o.order_ammount) AS total_order_amount
    from 
        orders o
    join 
        customers c on o.customer_id = c.customer_id
    group by 
        o.customer_id, c.name),
        --в этом cte находим данные по заказам, такие как среднее время доставки, сумма заказа

max_orders as (
    select  max(total_orders) as max_total_orders
    from customer_order_data)
    --находим максимальное кол-во заказов
select
    cod.customer_id,
    cod.name,
    cod.total_orders,
    cod.avg_delivery_time,
    cod.total_order_amount
from 
    customer_order_data cod
join 
    max_orders mo ON cod.total_orders = mo.max_total_orders
order by 
    cod.total_order_amount desc;
--------------------------------------------------------------------------------------------------------------------------
--Часть 1.3
with customer_order_info as (
    select 
        o.customer_id,
        c.name,
        --количество доставок с задержкой более 5 дней
        sum(case when date_part('day', o.shipment_date::timestamp - o.order_date::timestamp) > 5 then 1 else 0 end) as delayed_deliveries,
        -- также можно использовать count, тогда в case не нужно писать else
        --date_part необходим для того, чтобы извлечь кол-во дней, а не интервал, чтобы можно было сравнить его с 5
     
        --количество отмененных заказов
        sum(case when o.order_status = 'Cancel' then 1 else 0 end) as canceled_orders,
        
        --общая сумма задержанных заказов, но не отмененных заказов
        sum(case when date_part('day', o.shipment_date::timestamp - o.order_date::timestamp) > 5 
        and o.order_status != 'Cancel' then o.order_ammount else 0 end) as delayed_order_amount,
        
        --общая сумма всех отмененных заказов
        sum(case when o.order_status = 'Cancel' then o.order_ammount else 0 end) as canceled_order_amount
        --разбиение на разные категории "проблем" необходимо для того, чтобы задержанные и в последствии отмененные заказы не дублировались 
    from orders o
    join customers c ON o.customer_id = c.customer_id
    group by o.customer_id, c.name)
select
    customer_id,
    name,
    delayed_deliveries,
    canceled_orders,
    delayed_order_amount + canceled_order_amount AS total_problem_order_amount
from customer_order_info
where delayed_deliveries > 0 OR canceled_orders > 0
    --отбираем только проблемные заказы
order by total_problem_order_amount desc;
   