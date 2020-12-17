
select concat(format(Convert(datetime, month_of_year),'MMMM'), '-', format(Convert(datetime, date_of_year),'dd')) ,
temp_moving_average from 

(select  datepart(mm,CONVERT(DATETIME,Date_Local)) as month_of_year, datepart(dd,CONVERT(DATETIME,Date_Local)) date_of_year, 
 AVG(Average_Temp) temp_moving_average
from AQS_Sites a
inner join  Temperature  t  on
a.State_Code = t.State_Code
and
a.Site_Number =  t.Site_Num
where City_Name = 'Tucson'
group by datepart(mm,CONVERT(DATETIME,Date_Local)), datepart(dd,CONVERT(DATETIME,Date_Local)) 
) p
order by p. month_of_year, p.date_of_year

 
