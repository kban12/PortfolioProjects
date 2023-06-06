-- Exploration of Divvy Bike Share Fictional data

/* 
This data was imported from csv files provided as part of the Google Data Analysis Certificate program on Coursera.
The csv files were initially organized into both monthly records and quarterly records.
I imported them using the SQL Import Wizard, ensuring that each column's data type was correct for my purposes. 
For example, I changed the 'ride_id', 'start_station_id', and 'end_station_id' columns to a character data type from a numeric, 
because I would not be performing calculations with the columns's data.

In this project, I chose to merge and create new tables as well as modify the data in my existing tables. This was due to necessity in part,
as well as to demonstrate proficiency for this portfolio project. I understand however, that I may not have the authority or permissions 
to do so when working as a data analyst,as well as the importance of working within data management guidelines. I have included alternative
methods, where appropriate, that I would use instead of modifying tables or data. 
*/


-- Combine 3 monthly data tables into 1 quarterly table

-- To start, I counted the total rows across all three tables 

SELECT (
	SELECT COUNT(*) FROM dbo.[202004_divvy_tripdata]) + (
	SELECT COUNT(*) FROM dbo.[202005_divvy_tripdata]) + ( 
	SELECT COUNT(*) FROM dbo.[202006_divvy_tripdata]) 

-- This gave me a total of 628055 rows 

-- Next, I combined the three tables, and verified the number of rows in the new table

SELECT *
INTO Divvy_Trips_2020_Q2
FROM dbo.[202004_divvy_tripdata]
UNION ALL
SELECT *
FROM dbo.[202005_divvy_tripdata]
UNION ALL
SELECT *
FROM dbo.[202006_divvy_tripdata]

SELECT COUNT(*)
FROM Divvy_Trips_2020_Q2

-- This returned 628055 rows, verifing that all of the rows had been transferred.


-- Checking for errors in dataset

SELECT ride_id, started_at, ended_at, DATEDIFF(minute, started_at, ended_at) AS duration_min
FROM Divvy_Trips_2020_Q1
ORDER BY duration_min

-- Found almost 100 rows where the start and end time are reversed

/*
In order to fix these rows, I created two temporary tables. I used to first to collect the incorrect data and fix it. 
I then applied these changes to the second table, which contained all of the affected rows as well as rows which were already correct.
I did this to ensure that my fix only affected incorrect data in the selected columns.
*/

DROP TABLE IF EXISTS #TempSwap
SELECT TOP 100 ride_id, started_at, ended_at, DATEDIFF(second, started_at, ended_at) AS duration
INTO #TempSwap
FROM Divvy_Trips_2020_Q1
ORDER BY duration ASC

SELECT *
FROM #TempSwap
ORDER BY duration


UPDATE #TempSwap
SET started_at = ended_at, ended_at = started_at
WHERE duration < 0


DROP TABLE IF EXISTS #TempSwap2
SELECT TOP 130 ride_id, started_at, ended_at, DATEDIFF(second, started_at, ended_at) AS duration
INTO #TempSwap2
FROM Divvy_Trips_2020_Q1
ORDER BY duration ASC

SELECT *
FROM #TempSwap2
ORDER BY duration

UPDATE a
SET a.started_at=b.started_at, a.ended_at=b.ended_at
FROM #TempSwap2 AS a
INNER JOIN #TempSwap AS b ON a.ride_id = b.ride_id

-- As my soulution seems to work as intended, only changing the start and end times of the reversed rows, I will then apply it to the entire table


UPDATE a
SET a.started_at=b.started_at, a.ended_at=b.ended_at
FROM Divvy_Trips_2020_Q1 AS a
INNER JOIN #TempSwap AS b ON a.ride_id = b.ride_id

-- Checking a specific ride_id's start and end times, then the entire table

SELECT ride_id, started_at, ended_at, DATEDIFF(second, started_at, ended_at) AS duration
FROM Divvy_Trips_2020_Q1
WHERE ride_id = '6FABADDD595AF922'

SELECT ride_id, started_at, ended_at, DATEDIFF(second, started_at, ended_at) AS duration
FROM Divvy_Trips_2020_Q1
ORDER BY duration

-- Success! Moving on to checking for null values

SELECT * 
FROM  Divvy_Trips_2020_Q1
WHERE (ride_id IS NULL OR rideable_type IS NULL OR started_at IS NULL 
	OR ended_at IS NULL OR start_station_name IS NULL OR start_station_id IS NULL 
	OR end_station_name IS NULL OR end_station_id IS NULL OR start_lat IS NULL
	OR start_lng IS NULL OR end_lat IS NULL OR end_lng IS NULL 
	OR member_casual IS NULL) 

/* There is only one record with null values returned here, in the end station ID, name and latitude and longitude columns.
If one of these columns contained data, that could potentially be used to determine approximate values for the others, and updated, 
if appropriate. As they are all missing, my options are to find if this information has been stored elsewhere, document the missing 
values and move through the rest of my data exploration.
 */

-- Determining the amount of times a bike starts in a specific station

SELECT COUNT(start_station_name) AS CountName, start_station_name, start_station_id
FROM Divvy_Trips_2020_Q1
GROUP BY start_station_name, start_station_id
ORDER BY CountName DESC

-- Determining the amount of member rides versus non-member (casual) in the quarter

SELECT COUNT(member_casual) AS NumTrips, member_casual
FROM Divvy_Trips_2020_Q1
GROUP BY member_casual
ORDER BY NumTrips DESC

-- Determining the same as above, over two quarters

SELECT member_casual AS CustomerType, COUNT(member_casual) AS NumTripsQ1, (SELECT COUNT(member_casual) FROM Divvy_Trips_2020_Q2) AS NumTripsQ2
FROM Divvy_Trips_2020_Q1
GROUP BY member_casual

-- Determining top starting stations for quarter one and two

SELECT TOP 1000 COUNT(q1.ride_id) AS q1Count, COUNT(q2.ride_id) AS q2Count, q1.start_station_name
FROM Divvy_Trips_2020_Q1 AS q1
FULL OUTER JOIN Divvy_Trips_2020_Q2 AS q2 ON q1.start_station_name = q2.start_station_name
GROUP BY q1.start_station_name
ORDER BY q1Count DESC

-- Determining start stations with most and least amounts of rides

SELECT TOP 10 COUNT(ride_id) AS NumRides, start_station_name
FROM Divvy_Trips_2020_Q1
GROUP BY start_station_name
ORDER BY NumRides DESC

SELECT TOP 10 COUNT(ride_id) AS NumRides, start_station_name
FROM Divvy_Trips_2020_Q1
GROUP BY start_station_name
ORDER BY NumRides 

-- Narrowing scope to top 1000 longest trips

DROP TABLE IF EXISTS #LongestTrips
SELECT TOP 1000 ride_id, DATEDIFF(minute, started_at, ended_at) AS duration_min, member_casual
INTO #LongestTrips
FROM Divvy_Trips_2020_Q1
ORDER BY duration_min DESC

-- Determining average trip length of members vs casual riders from the top 1000 longest trips

SELECT (AVG(duration_min)/60) AS avgTripLengthHr, member_casual
FROM #LongestTrips
GROUP BY member_casual


