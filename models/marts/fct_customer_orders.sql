{{
    config(
        materialized='view'
    )
}}

with
customers as (

  select * from {{ ref('stg_jaffle_shop__customers') }}

),


orders as (

  select * from {{ ref('int_orders') }}

),

customer_orders as (
    select
        orders.*,
        customers.first_name,
        customers.last_name,

        -- nombre de commandes du client
        count(*) over (
            partition by orders.customer_id
        ) as order_count,

        -- nombre de commandes non retournées
        sum(nvl2(orders.valid_order_date, 1, 0)) over (
            partition by orders.customer_id
        ) as non_returned_order_count,

        -- valeur totale des commandes non retournées
        sum(nvl2(orders.valid_order_date, orders.total_amount_paid, 0)) over (
            partition by orders.customer_id
        ) as total_lifetime_value

    from orders
    inner join customers on orders.customer_id = customers.customer_id
),

add_avg_order_values as (
    select
        *,
        total_lifetime_value / nullif(non_returned_order_count, 0) 
            as avg_non_returned_order_value
    from customer_orders
),
-- Marts

final as (
    select
        order_id,
        customer_id,
        order_date,
        order_status,
        total_amount_paid,
        payment_finalized_date,
        first_name,
        last_name,
        order_count,
        non_returned_order_count,
        total_lifetime_value,
        avg_non_returned_order_value,

        -- sales transaction sequence
        row_number() over (
            order by order_date, order_id
        ) as transaction_seq,

        -- customer sales sequence
        row_number() over (
            partition by customer_id
            order by order_date, order_id
        ) as customer_sales_seq,

        -- new vs returning customer
        case
            when rank() over (
                partition by customer_id
                order by order_date, order_id
            ) = 1
            then 'new'
            else 'return'
        end as nvsr,

        -- customer lifetime value running total
        sum(total_amount_paid) over (
            partition by customer_id
            order by order_date, order_id
        ) as customer_lifetime_value,

        -- first day of sale
        first_value(order_date) over (
            partition by customer_id
            order by order_date, order_id
        ) as fdos

    from add_avg_order_values
)

select * from final
