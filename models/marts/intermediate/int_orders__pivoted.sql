{% set payment_methods= ['credit_card','gift_card','coupon','bank_transfer'] %} 

with

payments as (
    select * from {{ ref('stg_stripe__payment') }}
    where payment_status = 'success'
),

pivoted as (  
    select
    order_id,

        {%- for payment_method in payment_methods -%}
            sum(case when payment_method = '{{ payment_method }}' then payment_amount end) as {{ payment_method }}_amount
            {%- if not loop.last -%}
            ,
            {% endif %}
            
        {% endfor %}

    from payments
    group by 1
    )
    select * from pivoted