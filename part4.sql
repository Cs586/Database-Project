use Weather
IF EXISTS(SELECT 1 FROM sys.columns 
          WHERE Name = N'GeoLocation'
          AND Object_ID = Object_ID(N'dbo.AQS_Sites'))
BEGIN
    alter table AQS_Sites drop COLUMN GeoLocation;
END
go
alter table dbo.AQS_Sites add [GeoLocation] GEOGRAPHY
go

UPDATE [dbo].[AQS_Sites]
SET [GeoLocation] = geography::STPointFromText('POINT(' + convert(varchar, [Longitude]) + ' ' + 
                    convert(varchar, [Latitude]) + ')', 4326)
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
@longitude NVARCHAR(255),
@latitude NVARCHAR(255),
@State VARCHAR(Max),
@rownum bigint
as
Begin
    SET NOCOUNT ON; 
    DECLARE @h GEOGRAPHY
    SET @h = geography::STGeomFromText('POINT(' + @Latitude  + ' ' +  @Longitude + ')', 4326);
    with calculate_distance
    as
    (select 
    TOP (@rownum) GeoLocation.STDistance(@h) as [Distance_In_Meters], 
    GeoLocation.STDistance(@h)/80000 as [Hours_of_Travel],
    State_Name,
    (CASE
    when Local_Site_Name is null or Local_Site_Name = ''
    Then concat(convert(varchar, Site_Number), City_Name) 
    else Local_Site_Name
    end) as [Local_Site_Names],
    Zip_Code,
    Latitude, Longitude

    from AQS_Sites
    where State_Name = @State
    AND GeoLocation IS NOT NULL
    )
    select [Distance_In_Meters], Hours_of_Travel, Local_Site_Names,
    State_Name,
    Zip_Code,
    Latitude, Longitude 
    from calculate_distance
    where Zip_Code is not null 
END
GO 
EXEC WZ285_Fall2020_Calc_GEO_Distance @longitude='-86.472891', @latitude='32.437458', @State="Alabama", @rownum=1000

-- Select GeoLocation from AQS_Sites