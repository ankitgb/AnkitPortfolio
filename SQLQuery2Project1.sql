with applerev as (
SELECT date,
high,
low,
volume
from dbo.applerevenue)

select date,
volume,
(high - low) as range
from applerev