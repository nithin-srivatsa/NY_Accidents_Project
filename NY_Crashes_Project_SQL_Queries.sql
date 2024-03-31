--===================================================
-------------CREATE DIMENSION TABLES--------------
--==================================================

-- CREATE DATE DIMENSION TABLE
CREATE OR REPLACE TABLE Date_Dim (
    Date_Key INTEGER,
    Date DATE,
    Day SMALLINT,
    Month SMALLINT,
    Year SMALLINT,
    Quarter SMALLINT,
    Weekday_Name VARCHAR(10),
    Is_Weekend BOOLEAN
);

-- CREATE TIME DIMENSION TABLE
CREATE OR REPLACE TABLE Time_Dim (
    Time_Key INTEGER,
    Hour SMALLINT,
    Minute SMALLINT,
    Second SMALLINT,
    AM_PM VARCHAR(2),
    Time_Slot VARCHAR(20)
);

-- CREATE LOCATION DIMENSION TABLE
CREATE OR REPLACE TABLE Location_Dim (
    Location_Key INTEGER,
    Zip_Code VARCHAR(10)
);

-- CREATE VEHICLE DIMENSION TABLE
CREATE OR REPLACE TABLE Vehicle_Dim (
    Vehicle_Key INTEGER,
    Vehicle_Type VARCHAR(50)
);

-- CREATE CONTRIBUTING FACTOR DIMENSION TABLE
CREATE OR REPLACE TABLE Contributing_Factor_Dim (
    Factor_Key INTEGER,
    Contributing_Factor VARCHAR(255)
);
--===================================================
-------------CREATE FACT TABLE--------------
--==================================================

-- CREATE COLLISION FACT TABLE
CREATE OR REPLACE TABLE Collisions_Fact (
    Collision_Key INTEGER,
    Date_Key INTEGER,
    Time_Key INTEGER,
    Location_Key INTEGER,
    Vehicle_Key_1 INTEGER,
    Vehicle_Key_2 INTEGER,
    Vehicle_Key_3 INTEGER,
    Vehicle_Key_4 INTEGER,
    Vehicle_Key_5 INTEGER,
    Factor_Key_1 INTEGER,
    Factor_Key_2 INTEGER,
    Factor_Key_3 INTEGER,
    Factor_Key_4 INTEGER,
    Factor_Key_5 INTEGER,
    Number_of_Persons_Injured SMALLINT,
    Number_of_Persons_Killed SMALLINT,
    Number_of_Pedestrians_Injured SMALLINT,
    Number_of_Pedestrians_Killed SMALLINT,
    Number_of_Cyclists_Injured SMALLINT,
    Number_of_Cyclists_Killed SMALLINT,
    Number_of_Motorists_Injured SMALLINT,
    Number_of_Motorists_Killed SMALLINT,
    Collision_ID VARCHAR(50)
); 

--===================================================
-------------INSERT INTO DIMENSION TABLES--------------
--==================================================

-- INSERT INTO DATE DIMENSION TABLE
INSERT INTO Date_Dim (Date_Key, Date, Day, Month, Year, Quarter, Weekday_Name, Is_Weekend)
SELECT DISTINCT
    TO_CHAR(crash_date, 'YYYYMMDD')::INTEGER, 
    crash_date,                               
    DAY(crash_date),                         
    MONTH(crash_date),                        
    YEAR(crash_date),                         
    QUARTER(crash_date),                      
    DAYNAME(crash_date),                      
    IFF(DAYOFWEEKISO(crash_date) IN (6, 7), TRUE, FALSE) 
FROM MYDB.DM_MOTOR_VEHICLE_COLLISIONS_CRASHES.MOTOR_VEHICLE_COLLISION;

-- INSERT INTO TIME DIMENSION TABLE
INSERT INTO Time_Dim (Time_Key, Hour, Minute, Second, AM_PM, Time_Slot)
SELECT DISTINCT
    TO_CHAR(crash_time, 'HH24MI')::INTEGER,    
    EXTRACT(HOUR FROM crash_time),             
    EXTRACT(MINUTE FROM crash_time),           
    EXTRACT(SECOND FROM crash_time),           
    CASE WHEN EXTRACT(HOUR FROM crash_time) < 12 THEN 'AM' ELSE 'PM' END,
    CASE                                       
        WHEN EXTRACT(HOUR FROM crash_time) < 12 THEN 'Morning'
        WHEN EXTRACT(HOUR FROM crash_time) < 17 THEN 'Afternoon'
        WHEN EXTRACT(HOUR FROM crash_time) < 21 THEN 'Evening'
        ELSE 'Night'
    END
FROM MYDB.DM_MOTOR_VEHICLE_COLLISIONS_CRASHES.MOTOR_VEHICLE_COLLISION;

-- INSERT INTO LOCATION DIMENSION TABLE
INSERT INTO Location_Dim (Location_Key, Zip_Code)
SELECT 
    ROW_NUMBER() OVER(ORDER BY Zip_Code) AS Location_Key,
    Zip_Code
FROM (
    SELECT DISTINCT Zip_Code
    FROM MYDB.DM_MOTOR_VEHICLE_COLLISIONS_CRASHES.MOTOR_VEHICLE_COLLISION
) AS distinct_zip_codes;

-- INSERT INTO VEHICLE DIMENSION TABLE
INSERT INTO Vehicle_Dim (Vehicle_Key, Vehicle_Type)
SELECT DISTINCT
    ROW_NUMBER() OVER(ORDER BY vehicle_type_code),  
    vehicle_type_code                              
FROM (
    SELECT vehicle_type_code_1 AS vehicle_type_code FROM MYDB.DM_MOTOR_VEHICLE_COLLISIONS_CRASHES.MOTOR_VEHICLE_COLLISION
    UNION
    SELECT vehicle_type_code_2 FROM MYDB.DM_MOTOR_VEHICLE_COLLISIONS_CRASHES.MOTOR_VEHICLE_COLLISION
    UNION
    SELECT vehicle_type_code_3 FROM MYDB.DM_MOTOR_VEHICLE_COLLISIONS_CRASHES.MOTOR_VEHICLE_COLLISION
);

-- INSERT INTO CONTRIBUTING FACTOR DIMENSION TABLE
INSERT INTO Contributing_Factor_Dim (Factor_Key, Contributing_Factor)
SELECT DISTINCT
    ROW_NUMBER() OVER(ORDER BY contributing_factor),  
    contributing_factor                               
FROM (
    SELECT contributing_factor_vehicle_1 AS contributing_factor FROM MYDB.DM_MOTOR_VEHICLE_COLLISIONS_CRASHES.MOTOR_VEHICLE_COLLISION
    UNION
    SELECT contributing_factor_vehicle_2 FROM MYDB.DM_MOTOR_VEHICLE_COLLISIONS_CRASHES.MOTOR_VEHICLE_COLLISION
    UNION
    SELECT contributing_factor_vehicle_3 FROM MYDB.DM_MOTOR_VEHICLE_COLLISIONS_CRASHES.MOTOR_VEHICLE_COLLISION
);

--===================================================
-------------INSERT INTO FACT TABLE--------------
--==================================================
-- INSERT INTO COLLISION FACT TABLE
INSERT INTO Collisions_Fact (
    Collision_Key,
    Date_Key,
    Time_Key,
    Location_Key,
    Vehicle_Key_1,
    Vehicle_Key_2,
    Vehicle_Key_3,
    Vehicle_Key_4,
    Vehicle_Key_5,
    Factor_Key_1,
    Factor_Key_2,
    Factor_Key_3,
    Factor_Key_4,
    Factor_Key_5,
    Number_of_Persons_Injured,
    Number_of_Persons_Killed,
    Number_of_Pedestrians_Injured,
    Number_of_Pedestrians_Killed,
    Number_of_Cyclists_Injured,
    Number_of_Cyclists_Killed,
    Number_of_Motorists_Injured,
    Number_of_Motorists_Killed,
    Collision_ID
)
SELECT
    mv.COLLISION_ID AS Collision_Key,
    dd.Date_Key AS DATE_KEY,
    td.Time_Key AS Time_Key,
    ld.Location_Key AS Location_Key,
    vd1.Vehicle_Key AS Vehicle_Key_1,
    vd2.Vehicle_Key AS Vehicle_Key_2,
    vd3.Vehicle_Key AS Vehicle_Key_3,
    vd4.Vehicle_Key AS Vehicle_Key_4,
    vd5.Vehicle_Key AS Vehicle_Key_5,
    cfd1.Factor_Key AS Factor_Key_1,
    cfd2.Factor_Key AS Factor_Key_2,
    cfd3.Factor_Key AS Factor_Key_3,
    cfd4.Factor_Key AS Factor_Key_4,
    cfd5.Factor_Key AS Factor_Key_5,
    mv.NUMBER_OF_PERSONS_INJURED AS Number_of_Persons_Injured,
    mv.NUMBER_OF_PERSONS_KILLED AS Number_of_Persons_Killed,
    mv.NUMBER_OF_PEDESTRIANS_INJURED AS Number_of_Pedestrians_Injured,
    mv.NUMBER_OF_PEDESTRIANS_KILLED AS Number_of_Pedestrians_Killed,
    mv.NUMBER_OF_CYCLIST_INJURED AS Number_of_Cyclists_Injured,
    mv.NUMBER_OF_CYCLIST_KILLED AS Number_of_Cyclists_Killed,
    mv.NUMBER_OF_MOTORIST_INJURED AS Number_of_Motorists_Injured,
    mv.NUMBER_OF_MOTORIST_KILLED AS Number_of_Motorists_Killed,
    mv.COLLISION_ID AS Collision_ID
FROM  
    MYDB.DM_MOTOR_VEHICLE_COLLISIONS_CRASHES.MOTOR_VEHICLE_COLLISION mv
    LEFT JOIN 
        Contributing_Factor_Dim cfd1 ON mv.CONTRIBUTING_FACTOR_VEHICLE_1 = cfd1.Contributing_Factor
    LEFT JOIN 
        Contributing_Factor_Dim cfd2 ON mv.CONTRIBUTING_FACTOR_VEHICLE_2 = cfd2.Contributing_Factor
    LEFT JOIN 
        Contributing_Factor_Dim cfd3 ON mv.CONTRIBUTING_FACTOR_VEHICLE_3 = cfd3.Contributing_Factor
    LEFT JOIN 
        Contributing_Factor_Dim cfd4 ON mv.CONTRIBUTING_FACTOR_VEHICLE_4 = cfd4.Contributing_Factor
    LEFT JOIN 
        Contributing_Factor_Dim cfd5 ON mv.CONTRIBUTING_FACTOR_VEHICLE_5 = cfd5.Contributing_Factor
    LEFT JOIN 
        Vehicle_Dim vd1 ON mv.VEHICLE_TYPE_CODE_1 = vd1.Vehicle_Type
    LEFT JOIN 
        Vehicle_Dim vd2 ON mv.VEHICLE_TYPE_CODE_2 = vd2.Vehicle_Type
    LEFT JOIN 
        Vehicle_Dim vd3 ON mv.VEHICLE_TYPE_CODE_3 = vd3.Vehicle_Type
    LEFT JOIN 
        Vehicle_Dim vd4 ON mv.VEHICLE_TYPE_CODE_4 = vd4.Vehicle_Type
    LEFT JOIN 
        Vehicle_Dim vd5 ON mv.VEHICLE_TYPE_CODE_5 = vd5.Vehicle_Type
    LEFT JOIN 
        Date_Dim dd ON mv.CRASH_DATE = dd.Date
    LEFT JOIN 
        Location_Dim ld ON mv.ZIP_CODE = ld.Zip_Code
    LEFT JOIN 
        Time_Dim td ON CONCAT(LPAD(td.Hour, 2, '0'), ':', LPAD(td.Minute, 2, '0'), ':', LPAD(td.Second, 2, '0')) = TIME(mv.crash_time);


--===================================================
-------------Crashes by area--------------
--==================================================

SELECT
    ld.Borough,
    ld.Zip_Code, 
    COUNT(cf.Collision_Key) AS Total_Crashes
FROM 
    Collisions_Fact cf
JOIN 
    Location_Dim ld ON cf.Location_Key = ld.Location_Key
JOIN 
    Date_Dim dd ON cf.Date_Key = dd.Date_Key
WHERE 
    dd.Year = '2023'
GROUP BY
    ld.Borough,
    ld.Zip_Code
ORDER BY 
    COUNT(cf.Collision_Key) DESC;

--======================================================================
-------------Number of people injured by Contributing Factor--------------
--======================================================================
SELECT cfd.Contributing_Factor, SUM(cf.Number_of_Persons_Injured) AS Total_Injured
FROM Collisions_Fact cf
JOIN Contributing_Factor_Dim cfd 
ON cf.Factor_Key_1 = cfd.Factor_Key
JOIN Date_Dim dd 
ON cf.Date_Key = dd.Date_Key
WHERE dd.Year = '2023'
GROUP BY cfd.Contributing_Factor
ORDER BY Total_Injured DESC;


--===================================================
-------------Number of people killed by Contributing Factor--------------
--==================================================
SELECT cfd.Contributing_Factor, SUM(cf.Number_of_Persons_Killed) AS Total_Killed
FROM Collisions_Fact cf
JOIN Contributing_Factor_Dim cfd 
ON cf.Factor_Key_1 = cfd.Factor_Key
JOIN Date_Dim dd 
ON cf.Date_Key = dd.Date_Key
WHERE dd.Year = '2023'
GROUP BY cfd.Contributing_Factor
ORDER BY Total_Killed DESC;


--===================================================
-------------Injuries/Deaths per type of vehicle in the crash--------------
--==================================================
SELECT vd1.Vehicle_Type AS Vehicle_1, vd2.Vehicle_Type AS Vehicle_2,
    SUM(cf.Number_of_Persons_Injured) AS Total_Injured
FROM Collisions_Fact cf
JOIN Vehicle_Dim vd1 
ON cf.Vehicle_Key_1 = vd1.Vehicle_Key
JOIN Vehicle_Dim vd2 
ON cf.Vehicle_Key_2 = vd2.Vehicle_Key
JOIN Date_Dim dd 
ON cf.Date_Key = dd.Date_Key
WHERE dd.Year = '2023'
GROUP BY vd1.Vehicle_Type, vd2.Vehicle_Type
ORDER BY Total_Injured DESC;


--===================================================
-------------Injuries/Deaths vs Crashes rate:--------------
--==================================================
SELECT ld.Borough, ld.Zip_Code, dd.Year,
    (SUM(cf.Number_of_Persons_Injured) / COUNT(cf.Collision_Key)) * 100 AS Injuries_Crashes_Rate
FROM Collisions_Fact cf
JOIN Location_Dim ld 
ON cf.Location_Key = ld.Location_Key
JOIN Date_Dim dd 
ON cf.Date_Key = dd.Date_Key
WHERE dd.Year = '2023' AND ld.Borough = 'Brooklyn'
GROUP BY ld.Borough, ld.Zip_Code, dd.Year
ORDER BY ld.Borough, ld.Zip_Code, dd.Year;
