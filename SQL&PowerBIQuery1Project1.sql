with applerev as (
SELECT date,
high,
low,
volume
from dbo.applerevenue)

select
substring(date, 7, 4) AS Year,
sum(volume) as Revenue
from applerev
group by substring(date, 7, 4)
order by year desc;
