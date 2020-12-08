use Weather
Alter table AQS_Sites alter Column latitude float
Alter table AQS_Sites alter Column longitude float
Alter table Guncrimes alter Column latitude float
Alter table Guncrimes alter Column longitude float

Alter table Guncrimes alter Column n_injured float
Alter table Guncrimes alter Column n_killed float

-- add in  geolocation column for both table
IF EXISTS(SELECT 1 FROM sys.columns 
          WHERE Name = N'GeoLocation'
          AND Object_ID = Object_ID(N'dbo.AQS_Sites'))
BEGIN
    alter table AQS_Sites drop COLUMN GeoLocation;
END
go
alter table dbo.AQS_Sites add GeoLocation GEOGRAPHY;
go

IF EXISTS(SELECT 1 FROM sys.columns 
          WHERE Name = N'GeoLocation'
          AND Object_ID = Object_ID(N'dbo.GunCrimes'))
BEGIN
    alter table GunCrimes drop COLUMN GeoLocation;
END
go
alter table dbo.GunCrimes add GeoLocation GEOGRAPHY;
go


UPDATE [dbo].[AQS_Sites]
SET [GeoLocation] = geography::STPointFromText('POINT(' + CAST([Longitude] AS VARCHAR(50)) + ' ' + CAST([Latitude] AS VARCHAR(50)) + ')', 4326)
where Latitude <> 0 and Longitude <> 0
go

UPDATE [dbo].[GunCrimes]
SET [GeoLocation] = geography::STPointFromText('POINT(' + CAST([Longitude] AS VARCHAR(50)) + ' ' + CAST([Latitude] AS VARCHAR(50)) + ')', 4326)
where Latitude <> 0 and Longitude <> 0



IF EXISTS(SELECT 1 FROM sys.columns 
          WHERE Name = N'GeoDistance'
          AND Object_ID = Object_ID(N'dbo.GunCrimes'))
BEGIN
    alter table GunCrimes drop COLUMN GeoDistance;
END
go
alter table dbo.GunCrimes add GeoDistance float;
go
begin
DECLARE @h GEOGRAPHY;
SET @h = geography::STGeomFromText('POINT(' + '-86.472891' + ' ' + '32.437458' + ')', 4326);
UPDATE [dbo].GunCrimes
SET [GeoDistance] = GunCrimes.GeoLocation.STDistance(@h)
end
go




IF EXISTS(SELECT 1 FROM sys.columns 
          WHERE Name = N'GeoDistance'
          AND Object_ID = Object_ID(N'dbo.AQS_Sites'))
BEGIN
    alter table AQS_Sites drop COLUMN GeoDistance;
END
go
alter table dbo.AQS_Sites add GeoDistance float;
GO
begin 
DECLARE @h GEOGRAPHY;
SET @h = geography::STGeomFromText('POINT(' + '-86.472891' + ' ' + '32.437458' + ')', 4326);
UPDATE [dbo].AQS_Sites
SET [GeoDistance] = AQS_Sites.GeoLocation.STDistance(@h)
where GeoLocation is not null
end
go

with samp as (
    select count(distinct incident_id) [shooting_count], 
    concat(convert(varchar,Site_Number),'-',State_Name,'-',a.Address) as Local_Site_Name,
    City_Name, State_Name, year(date) as Crime_year from GunCrimes g, AQS_Sites a
    where 
    g.Geodistance <= (10 * 1600)
    and
    a.Geodistance <= (10 * 1600)
    and
    incident_characteristics like 'Shot%'
    group by
    concat(convert(varchar,Site_Number),'-',State_Name,'-',a.Address),
    City_Name, State_Name,
    year(date)
)

select Local_Site_Name, City_Name, Crime_Year, Shooting_Count, Rank()OVER(
PARTITION BY State_Name
ORDER BY Shooting_Count
) Shooting_Count_Rank
from samp
