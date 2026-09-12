{% macro limit_data_in_dev(column_name, dev_limit=100) %}
    {% if target.name == 'dev' %}
        order by {{ column_name }}
        limit {{ dev_limit }}
    {% endif %}
{% endmacro %}