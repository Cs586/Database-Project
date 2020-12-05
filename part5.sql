use Weather
Alter table AQS_Sites alter Column latitude float
Alter table AQS_Sites alter Column longitude float
Alter table Guncrimes alter Column latitude float
Alter table Guncrimes alter Column longitude float

Alter table Guncrimes alter Column n_injured float
Alter table Guncrimes alter Column n_killed float


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
UPDATE [dbo].GunCrimes
SET [GeoLocation] = geography::STPointFromText('POINT(' + CAST([Longitude] AS VARCHAR(50)) + ' ' + CAST([Latitude] AS VARCHAR(50)) + ')', 4326)
where Latitude <> 0 and Longitude <> 0
go

IF EXISTS ( SELECT  *
            FROM    sys.objects
            WHERE   object_id = OBJECT_ID(N'WZ285_Fall2020_Calc_GEO_Distance')
                    AND type IN ( N'P', N'PC' ) ) 
BEGIN
DROP PROCEDURE dbo.WZ285_Fall2020_Calc_GEO_Distance
END
GO
Create PROCEDURE dbo.WZ285_Fall2020_Calc_GEO_Distance
@longitude VARCHAR(50),
@latitude VARCHAR(50),
@State VARCHAR(Max),
@rownum bigint
as
Begin
    SET NOCOUNT ON; 
    DECLARE @h GEOGRAPHY
    SET @h = geography::STGeomFromText('POINT(' + @Longitude + ' ' + @Latitude + ')', 4326);
    with calculate_distance
    as
    (select 
    TOP (@rownum) GeoLocation.STDistance(@h) as [Distance_In_Meters], 
    GeoLocation.STDistance(@h)/80000 as [Hours_of_Travel], 
    (CASE
    when Local_Site_Name is null or Local_Site_Name = ''
    Then concat(convert(varchar, Site_Number), City_Name) 
    else Local_Site_Name
    end) [Local_Site_Names]
    from AQS_Sites
    where State_Name = @State
    AND GeoLocation IS NOT NULL
    )
    select [Distance_In_Meters], Hours_of_Travel, Local_Site_Names from calculate_distance
END
GO 


With ST as
(select count(g.incident_characteristics)as N,convert(varchar(8000),g.GeoLocation)as Names
	from GunCrimes g 
	where incident_characteristics like 'shot%' and
	g.GeoLocation.STDistance(g.GeoLocation)< (10 * 1609.344)
	group by convert(varchar(8000),g.GeoLocation))
select top(1000) (Site_Number+'-'+State_Name+'-'+a.Address) as Local_Site_Name, City_Name, year(date) as Crime_year
	, count(s.N) as Shooting_Count
	from GunCrimes g,AQS_Sites a, ST s
where g.GeoLocation.STDistance(g.GeoLocation)=a.GeoLocation.STDistance(a.GeoLocation) and
	convert(varchar(8000),a.GeoLocation)= s.Names
Group by year(date),City_Name,(Site_Number+'-'+State_Name+'-'+a.Address)
Order by Shooting_Count,year(date),City_Name;
