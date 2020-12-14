use Weather;
-- 1.	Determine the date range of the records in the Temperature table
-- First Date	Last Date
-- 1986-01-01	2017-05-09

select min(Date_Last_Change) as [First Date], max(Date_Last_Change) as [Last Date] from Temperature

-- 2.	Find the minimum, maximum and average temperature for each state
-- State_Name	Minimum Temp	Maximum Temp	Average Temp
-- Alabama	-4.662500		88.383333		59.328094
-- Alaska		-43.875000		80.791667		29.146757
-- Arizona	-99.000000		135.500000		67.039050

select State_Name, min(Average_Temp) as [Minimum Temp], max(Average_Temp) [Maximum Temp], avg(Average_Temp) [Average Temp] 
from
(select State_Name, Average_Temp from 
Temperature  t , AQS_Sites a
where
t.Site_Num  = a.Site_Number )p
group by State_Name
;

-- 3.	The results from question #2 show issues with the database.  Obviously, a temperature of -99 degrees Fahrenheit in Arizona is not an accurate reading as most likely is 135.5 degrees.  Write the queries to find all suspect temperatures (below -39o and above 105o). Sort your output by State Name and Average Temperature.

-- State_Name	state_code	County_Code	Site_Number	average_Temp	date_local
-- Wisconsin	55		059		0002		-58.000000		2002-03-28
-- Washington	53		009		0013		-50.000000		2012-10-17
-- Texas		48		141		0050		106.041667		1991-07-28
-- Texas		48		141		0050		106.291667		1991-07-25
go

SELECT distinct a.State_Name [State Name],t.State_Code [State Code],t.County_Code [County Code],t.Site_Num [Site Number],t.Average_Temp [Average Temp],t.Date_Local [Date Local] 
 FROM Temperature t
 LEFT JOIN AQS_Sites a ON a.State_Code = t.State_Code and a.County_Code = t.County_Code and a.Site_Number = t.Site_Num 
 WHERE  t.Average_Temp <-39 or t.Average_Temp>105

go

-- 4.	You noticed that the average temperatures become questionable below -39 o and above 125 o and that it is unreasonable to have temperatures over 105 o for state codes 30, 29, 37, 26, 18, 38. You also decide that you are only interested in living in the United States, not Canada or the US territories. Create a view that combines the data in the AQS_Sites and Temperature tables. The view should have the appropriate SQL to exclude the data above. You should use this view for all subsequent queries.
IF EXISTS(select * FROM sys.views where name = 'Refined_Temperature_Data')
BEGIN
DROP VIEW Refined_Temperature_Data
END
GO
CREATE VIEW Refined_Temperature_Data AS
WITH
Temperature_Data AS
(
	/* 
	Because we want to EXCLUDE any points where the Average Temp is less than -39 degrees and greater than 125 degrees
	our logical statment is going to look for any temperatures between -39 and 125 degrees
	*/
	SELECT * FROM Temperature
	WHERE Average_Temp > -39 OR Average_Temp < 125
	/* NOTE: THE STATEMENT BELOW IS NOT BEING SCRIPTED UNDER INSTRUCTIONS FROM THE PROFESSOR */
	/* unreasonable to have temperatures over 105 o for state codes 30, 29, 37, 26, 18, 38 */
	/* Used for testing purposes */
	/* ORDER BY Average_Temp ASC */
),
AQS_data AS 
(
	/* decide that you are only interested in living in the United States, not Canada or the US territories */
	SELECT * FROM AQS_Sites
	WHERE State_Name NOT IN ('Canada','Country Of Mexico','District Of Columbia','Guam','Puerto Rico','Virgin Islands')
)
SELECT Temperature_Data.State_Code, State_Name, Temperature_Data.County_Code, Temperature_Data.Site_Num, Average_Temp
FROM Temperature_Data, AQS_data
WHERE Temperature_Data.State_Code = AQS_data.State_Code AND Temperature_Data.Site_Num = AQS_data.Site_Number AND  Temperature_Data.County_Code = AQS_data.County_Code

/* Test Statement Below returns 5,607,733 rows */
/* Select * from Refined_Temperature_Data */
/*
SELECT Temperature_Data.State_Code, Temperature_Data.Site_Num, Temperature_Data.County_Code,Date_Local, Average_Temp, Daily_High_Temp,
Date_Last_Change, Temperature_Data.[1st Max Hour], Latitude, Longitude, Datum, Elevation, [Land Use], [Location Setting],
[Site Established Date], [Site Closed Date], [Met Site State Code], [Met Site County Code], [Met Site Site Number], [Met Site Type],
[Met Site Distance], [Met Site Direction], [GMT Offset], [Owning Agency], Local_Site_Name, Address, Zip_Code,
State_Name, County_Name, City_Name, CBSA_Name, Tribe_Name, [Extraction Date]
*/
/* The view includes the State_code, State_Name, County_Code, Site_Number */
/* Also need to include Average Temp*/
GO
BEGIN
Select * from Refined_Temperature_Data
END


-- 5.	Using the SQL RANK statement, rank the states by Average Temperature
-- State_Name	Minimum Temp		Maximum Temp		Average Temp	State_rank
-- Florida	35.96			88.00			72.244255		1
-- Louisiana	22.13			91.67			69.359993		2
-- Texas	0.00			122.60			68.906944		3
SELECT State_Name, MIN(Average_Temp) AS 'Minimum Temp', MAX(ABS(Average_Temp)) AS 'Maximum Temp', AVG(Average_Temp) AS 'Average Temp', RANK() OVER(ORDER BY AVG(Average_Temp) DESC) AS 'State_rank'
FROM Refined_Temperature_Data
GROUP BY State_Name
ORDER BY State_rank

-- 6.	At this point, you’ve started to become annoyed at the amount of time each query is taking to run. You’ve heard that creating indexes can speed up queries. Create 5 indexes for your database. 2 of the indexes should index the temperature fields in the Temperature table, 1 index for the date in the Temperature table and 2 would index the columns used for joining the 2 tables (state, County and Site codes in the Temperate and aqs_site tables). 

-- To see if the indexing help, add print statements that write the start and stop time for the query in question #2 and run the query before and after the indexes are created. Note the differences in the times. Also make sure that the create index steps include a check to see if the index exists before trying to create it.

-- The following is a sample of the output that should appear in the messages tab that you will need to calculate the difference in execution times before and after the indexes are created

-- Begin Question 6 before Index Create At - 13:40:03
-- (777 row(s) affected)
-- Complete Question 6 before Index Create At - 13:45:18

DECLARE @StartTime datetime
DECLARE @EndTime datetime
SELECT @StartTime = GETDATE()

/* Display print required before statement */
Print 'Before Question 6, the execution of the query started at - ' + (CAST(convert(varchar,getdate(),108) AS nvarchar(30)))

/* Query of Question #2 */
SELECT State_Name, MIN(Average_Temp) AS [MINIMUM TEMP], MAX(Average_Temp) AS [MAX TEMP], AVG(Average_Temp) AS [TEMP AVG]
FROM Temperature, AQS_Sites
WHERE Temperature.State_Code = AQS_Sites.State_Code AND Temperature.County_Code = AQS_Sites.County_Code AND Temperature.Site_Num = AQS_Sites.Site_Number
GROUP BY State_Name
ORDER BY State_Name

SELECT @EndTime=GETDATE()
PRINT 'Before Question 6, the execution of the query ended at - ' + (CAST(convert(varchar,getdate(),108) AS nvarchar(30)))

/* Provide the execution time in milliseconds before indexing */
PRINT 'The execution time in milliseconds before Indexing: ' +(CAST(convert(varchar,DATEDIFF(millisecond,@StartTime,@EndTime),108) AS nvarchar(30)))

/* Check to see if the Average_Temp_Index exists before and create it if it doesn't */
GO
BEGIN
	IF EXISTS (SELECT *  FROM SYS.INDEXES
	WHERE name in (N'Average_Temp_Index') AND object_id = OBJECT_ID('dbo.Temperature'))
	BEGIN
		DROP INDEX Average_Temp_Index ON Temperature
	END
END

/* Next create index for Average_Temp column in Temperature table */
GO
Create Index Average_Temp_Index ON Temperature (Average_Temp)

/* Checking if the Daily_High_Temp_Index exists before creating it */
GO
BEGIN
	IF EXISTS (SELECT *  FROM SYS.INDEXES
	WHERE name in (N'Daily_High_Temp_Index') AND object_id = OBJECT_ID('dbo.Temperature'))
	BEGIN
		DROP INDEX Daily_High_Temp_Index ON Temperature
	END
END

/* Creating index for Daily_High_Temp column in Temperature table */
GO
Create Index Daily_High_Temp_Index ON Temperature (Daily_High_Temp)

/* Checking if the Date_Local_Index exists before creating it */
GO
BEGIN
	IF EXISTS (SELECT *  FROM SYS.INDEXES
	WHERE name in (N'Date_Local_Index') AND object_id = OBJECT_ID('dbo.Temperature'))
	BEGIN
		DROP INDEX Date_Local_Index ON Temperature
	END
END

/* Creating index for Date_Local column in Temperature table */
GO
Create Index Date_Local_Index ON Temperature (Date_Local)

/* Checking if the State_County_Site_Code_Temp_Index exists before creating it */
GO
	BEGIN
	IF EXISTS (SELECT *  FROM SYS.INDEXES
	WHERE name in (N'State_County_Site_Code_Temp_Index') AND object_id = OBJECT_ID('dbo.Temperature'))
	BEGIN
		DROP INDEX State_County_Site_Code_Temp_Index ON Temperature
	END
END

/* Creating Indexes on County_Code, State_Code, Site_Num in Temperature table */
GO
Create Index State_County_Site_Code_Temp_Index ON Temperature (State_Code, County_Code, Site_Num)

/* Checking if the State_County_Site_Code_AQS_Index exists before creating it */
GO
BEGIN
	IF EXISTS (SELECT *  FROM SYS.INDEXES
	WHERE name in (N'State_County_Site_Code_AQS_Index') AND object_id = OBJECT_ID('dbo.aqs_sites'))
	BEGIN
		DROP INDEX State_County_Site_Code_AQS_Index ON aqs_sites
	END
END

/* Creating Indexes on County_Code, State_Code, Site_Num in aqs_sites table */
GO
Create Index State_County_Site_Code_AQS_Index ON AQ (State_Code,county_code, Site_Number)

/* The portion below after all indexing is completed */
GO
DECLARE @StartTimeAfterIndex datetime
DECLARE @EndTimeAfterIndex datetime
SELECT @StartTimeAfterIndex = GETDATE()

Print 'After Question 6, the execution of the query started at - ' + (CAST(CONVERT(VARCHAR, GETDATE(),108) AS NVARCHAR(30)))

/* Query of Question 2 --> AGAIN! */

SELECT State_Name,MIN(Average_Temp) AS [Minimum_Temp], MAX(Average_Temp) AS [Maximum_Temp], AVG(Average_Temp) AS [Temp_Avg]
FROM Temperature , AQS_Sites
WHERE Temperature.State_Code = AQS_Sites.State_Code AND Temperature.County_Code = AQS_Sites.County_Code AND Temperature.Site_Num = AQS_Sites.Site_Number
GROUP BY State_Name
ORDER BY State_Name

SELECT @EndTimeAfterIndex=GETDATE()
PRINT 'After Question 6, the execution of the query ended at - ' + (CAST(CONVERT(VARCHAR, GETDATE(),108) AS NVARCHAR(30)))

/* This query gives the execution time in milliseconds afer indexing */
PRINT 'The execution time in milliseconds after Indexing: ' +
		(CAST(CONVERT(VARCHAR,DATEDIFF(MILLISECOND, @StartTimeAfterIndex,@EndTimeAfterIndex),108) AS nvarchar(30)))




-- 7.	You’ve decided that you want to see the ranking of each high temperatures for each city in each state to see if that helps you decide where to live. Write a query that ranks (using the rank function) the states by averages temperature and then ranks the cities in each state. The ranking of the cities should restart at 1 when the query returns a new state. You also want to only show results for the 15 states with the highest average temperatures.

-- Note: you will need to use multiple nested queries to get the State and City rankings, join them together and then apply a where clause to limit the state ranks shown.

-- State_Rank	State_Name	State_City_Rank	City_Name	   Average Temp
-- 1		Florida		1			Not in a City	   73.975759
-- 1		Florida		2			Pinellas Park	   72.878784
-- 1		Florida		3			Valrico		   71.729440
-- 1		Florida		4			Saint Marks	   69.594272
-- 2		Texas		1			McKinney	   76.662423
-- 2		Texas		2			Mission	   74.701098

go
With 
state_rank  as
    (SELECT
        State_Name, Site_Number,
        RANK () OVER ( 
            ORDER BY Average_Temp DESC
        ) state_rank
    FROM
        Temperature t , AQS_Sites a
    where 
    t.State_Code = a.State_Code), 
city_rank as 
    (SELECT City_Name, Site_Number,
    RANK() OVER (
        PARTITION BY a.State_Name
        ORDER BY Average_Temp DESC
    ) city_rank
    from Temperature t, AQS_Sites a
    where
    t.Site_Num = a.Site_Number
)
select s.State_Name, state_rank, c.City_Name, city_rank from state_rank s, city_rank c, AQS_Sites a
where 
s.Site_Number = c.Site_Number
and
c.Site_Number = a.Site_Number

-- 8.	You notice in the results that sites with Not in a City as the City Name are include but do not provide you useful information. Exclude these sites from all future answers. You can do this by either adding it to the where clause in the remaining queries or updating the view you created in #4

--  
go
With 
state_rank  as
    (SELECT
        State_Name, Site_Number,
        RANK () OVER ( 
            ORDER BY Average_Temp DESC
        ) state_rank
    FROM
        Temperature t , AQS_Sites a
    where 
    t.State_Code = a.State_Code), 
city_rank as 
    (SELECT City_Name, Site_Number,
    RANK() OVER (
        PARTITION BY a.State_Name
        ORDER BY Average_Temp DESC
    ) city_rank
    from Temperature t, AQS_Sites a
    where
    t.Site_Num = a.Site_Number
)
select s.State_Name, state_rank, c.City_Name, city_rank from state_rank s, city_rank c, AQS_Sites a
where 
s.Site_Number = c.Site_Number
and
c.Site_Number = a.Site_Number
and
c.City_Name <> 'Not in a City'

-- 9.	You’ve decided that the results in #8 provided too much information and you only want to 2 cities with the highest temperatures and group the results by state rank then city rank. 

-- State_Rank	State_Name	State_City_Rank	City_Name		Average Temp
-- 1		Florida		1			Pinellas Park		72.878784
-- 1		Florida		2			Valrico			71.729440
-- 2		Louisiana	1			Baton Rouge		69.704466
-- 2		Louisiana	2			Laplace (La Place)	68.115400

go
With 
state_rank  as
    (SELECT
        State_Name, Site_Number,
        RANK () OVER ( 
            ORDER BY Average_Temp DESC
        ) state_rank
    FROM
        Temperature t , AQS_Sites a
    where 
    t.State_Code = a.State_Code), 
city_rank as 
    (SELECT City_Name, Site_Number,
    RANK() OVER (
        PARTITION BY a.State_Name
        ORDER BY Average_Temp DESC
    ) city_rank
    from Temperature t, AQS_Sites a
    where
    t.Site_Num = a.Site_Number
)
select s.State_Name, state_rank, c.City_Name, city_rank from state_rank s, city_rank c, AQS_Sites a
where 
s.Site_Number = c.Site_Number
and
c.Site_Number = a.Site_Number
and
c.City_Name <> 'Not in a City'
and
city_rank <= 2

-- 10.	You decide you like the average temperature to be in the 80's. Pick 3 cities that meets this condition and calculate the average temperature by month for those 3cities. You also decide to include a count of the number of records for each of the cities to make sure your comparisons are being made with comparable data for each city. 

-- Hint, use the datepart function to identify the month for your calculations.

-- City_Name	Month	# of Records	Average Temp
-- Mission	1	620		60.794048
-- Mission	2	565		64.403861
-- Mission	3	588		69.727512

	SELECT a.City_Name [City Name],DATEPART(MONTH,t.Date_Local) [Month], Count(t.Average_Temp) [# of Records], AVG(Average_Temp) [Average Temp]
	from Temperature t 
	INNER JOIN AQS_Sites a on a.State_Code = a.State_Code and a.County_Code = t.County_Code and a.Site_Number = t.Site_Num
	WHERE a.City_Name in ('Mission') and City_Name <> 'Not in a City'
	Group by a.City_Name,DATEPART(MONTH,t.Date_Local) 
	Order by a.City_Name ,DATEPART(MONTH,t.Date_Local) 

	--For 3 cities
	SELECT a.City_Name [City Name],DATEPART(MONTH,t.Date_Local) [Month], Count(t.Average_Temp) [# of Records], AVG(Average_Temp) [Average Temp]
	from Temperature t 
	INNER JOIN AQS_Sites a on a.State_Code = t.State_Code and a.County_Code = t.County_Code and a.Site_Number = t.Site_Num
	WHERE a.City_Name in ('Mission','Pinellas Park','Tucson') and City_Name <> 'Not in a City'
	Group by a.City_Name,DATEPART(MONTH,t.Date_Local) 
	Order by a.City_Name ,DATEPART(MONTH,t.Date_Local) 

-- 11.	You assume that the temperatures follow a normal distribution and that the majority of the temperatures will fall within the 40% to 60% range of the cumulative distribution. Using the CUME_DIST function, show the temperatures for the same 3 cities that fall within the range.

-- City_Name	Avg_Temp	Temp_Cume_Dist
-- Mission	73.916667	0.400686891814539
-- Mission	73.956522	0.400829994275902
-- Mission	73.958333	0.402404121350887 

	SELECT A.City_Name [City_Name], A.Average_Temp [Avg_Temp], A.CumeDist [Temp_Cume_Dist]
	FROM
	(
	SELECT distinct a.City_Name, Average_Temp, 
	CUME_DIST () OVER (PARTITION BY a.city_name ORDER BY Average_Temp) AS CumeDist
	from Temperature t
	INNER JOIN AQS_Sites a on a.State_Code = a.State_Code and a.County_Code = a.County_Code and a.Site_Number = t.Site_Num
	Where City_Name in ('Mission','Pinellas Park','Tucson') and City_Name <> 'Not in a City'
	) A
	Where ROUND(A.CumeDist,3)> 0.400 and ROUND(A.CumeDist,3)< 0.600
	Order by A.City_Name,A.Average_Temp,A.CumeDist

-- 12.	You decide this is helpful, but too much information. You decide to write a query that shows the first temperature and the last temperature that fall within the 40% and 60% range for the 3 cities your focusing on.

-- City_Name	40 Percentile Temp	60 Percentile Temp
-- Mission	73.956522		80.083333
-- Pinellas Park	71.958333		78.125000
-- Tucson	63.750000		74.250000

	SELECT AB.City_Name,MIN(AB.Avg_Temp) [40 Percentile Temp],MAX(AB.Avg_Temp) [60 Percentile Temp]
	FROM
	(
		SELECT A.City_Name [City_Name], A.Average_Temp [Avg_Temp], A.CumeDist,A.PercentRank
		FROM
		(
		SELECT distinct a.City_Name, Average_Temp, 
		CUME_DIST () OVER (PARTITION BY a.city_name ORDER BY Average_Temp) AS CumeDist,
		PERCENT_RANK() OVER (PARTITION BY a.city_name ORDER BY Average_Temp ) as PercentRank
		from Temperature t
		INNER JOIN AQS_Sites a on a.State_Code = t.State_Code and a.County_Code = t.County_Code and a.Site_Number = t.Site_Num
		Where City_Name in ('Mission','Pinellas Park','Tucson') and City_Name <> 'Not in a City'
		) A
		Where ROUND(A.PercentRank,4)> 0.400 and ROUND(A.PercentRank,4)< 0.600
	)AB  
	Group by AB.City_Name

-- 13.	You remember from your statistics classes that to get a smoother distribution of the temperatures and eliminate the small daily changes that you should use a moving average instead of the actual temperatures. Using the windowing within a ranking function to create a 4 day moving average, calculate the moving average for each day of the year. 

-- Hint: You will need to datepart to get the day of the year for your moving average. You moving average should use the 3 days prior and 1 day after for the moving average.

-- City_Name	Day of the Year	Rolling_Avg_Temp
-- Mission	1			59.022719
-- Mission	2			58.524868
-- Mission	3			58.812967

-- Mission	364			60.657749
-- Mission	365			61.726333
-- Mission	366			61.972514 

	SELECT AB.[City Name],AB.DayYear,
	AVG(AB.Temp) over(partition by AB.[City Name] order by AB.DayYear rows between 3 preceding and 1 following) as [Rolling Avg Temp]
	FROM
	(
	SELECT a.City_Name [City Name],DATEPART(DAYOFYEAR,Date_Local) [DayYear],AVG(Average_Temp) [Temp]
	from Temperature t 
	INNER JOIN AQS_Sites a on a.State_Code = t.State_Code and a.County_Code = t.County_Code and a.Site_Number = t.Site_Num
	WHERE a.City_Name in ('Mission','Pinellas Park','Tucson') and City_Name <> 'Not in a City'
	 group by a.City_Name, DATEPART(DAYOFYEAR,Date_Local)
	 ) AB
	order by AB.[City Name],AB.DayYear
	GO
