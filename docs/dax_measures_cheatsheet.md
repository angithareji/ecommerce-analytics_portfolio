# DAX Measures Cheat-Sheet (Starter Set)

## Executive KPI Dashboard
```dax
Total Revenue = SUM(dw_monthly_order_metrics[revenue_recognized])
Orders = SUM(dw_monthly_order_metrics[orders_recognized])
AOV = DIVIDE([Total Revenue], [Orders])

Refunded Revenue = SUM(dw_monthly_order_metrics[revenue_refunded])
Refund % = DIVIDE([Refunded Revenue], [Total Revenue])

Bad Orders = SUM(dw_monthly_order_metrics[orders_bad])
Bad Order Rate = DIVIDE([Bad Orders], [Orders])

Revenue Prev Month = CALCULATE([Total Revenue], PREVIOUSMONTH(dim_date[Date]))
MoM Revenue % = DIVIDE([Total Revenue] - [Revenue Prev Month], [Revenue Prev Month])

Revenue Prev Year = CALCULATE([Total Revenue], SAMEPERIODLASTYEAR(dim_date[Date]))
YoY Revenue % = DIVIDE([Total Revenue] - [Revenue Prev Year], [Revenue Prev Year])
```

## Retention Studio (RFM)
```dax
Customer LTV = SUM(dw_customer_lifetime[lifetime_revenue])

Repeat Customers =
COUNTROWS(
    FILTER(
        VALUES(dw_customer_lifetime[customer_id]),
        CALCULATE(MAX(dw_customer_lifetime[total_orders])) > 1
    )
)
Repeat Rate = DIVIDE([Repeat Customers], DISTINCTCOUNT(dw_customer_lifetime[customer_id]))
```
