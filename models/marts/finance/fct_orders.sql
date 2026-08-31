-- models/marts/fct_orders.sql

with orders as (
    select * from {{ ref('stg_jaffle_shop__orders') }}
),

payments as (
    select * from {{ ref('stg_stripe__payments') }}
),

order_payment as (
    select
        order_id,
        sum (case when status = 'success' then amount end) as amount

    from payments
    group by 1
),

final as (
    select
        orders.order_id,
        orders.customer_id,
        orders.order_date,
        coalesce(order_payment.amount,0) as amount
    from orders
    left join order_payment
    on orders.order_id = order_payment.order_id
)

select * from final