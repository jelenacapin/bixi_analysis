USE bixi;

# view first ten rows in stations table
SELECT *
FROM stations
LIMIT 10;

# view first ten rows in trips table
SELECT * 
FROM trips
LIMIT 10;
  
# get total number of trips by year   
# Total trips in 2016: 3,917,401

SELECT COUNT(*) 
FROM trips
WHERE start_date >= '2016-01-01' AND start_date < '2017-01-01';

# Total trips in 2017: 4,666,765

SELECT COUNT(*) 
FROM trips
WHERE start_date >= '2017-01-01' AND start_date < '2018-01-01';

# get monthly trips for each year in the dataset
# monthly trips for 2016: April 189,923 / May 561,077 / June 631,503 / July 699,248 / Aug 672,778 / Sept 620,263 / Oct 392,480 / Nov 150,129

SELECT (MONTH(start_date)) AS Month, COUNT(*)
FROM trips 
WHERE YEAR(start_date) = 2016
GROUP BY (MONTH(start_date));

# monthly trips for 2017: April 195,662 / May 587,447 / June 741,835 / July 860,732 / Aug 839,938 / Sept 731,851 / Oct 559,506 / Nov 149,794

SELECT (MONTH(start_date)) AS Month, COUNT(*)
FROM trips 
WHERE YEAR(start_date) = 2017
GROUP BY (MONTH(start_date));

# get the avg number of trips per day for each year-month combo in the dataset 

SELECT 
		MONTH(start_date) AS Mo, 
        YEAR(start_date) AS Yr, 
        COUNT(*)/(COUNT(DISTINCT(DAY(start_date)))) AS Avg_Daily_Trips
FROM trips
GROUP BY Yr, Mo;

# create new table containing above ouput

CREATE TABLE working_table1 AS
SELECT 
		MONTH(start_date) AS Mo, 
        YEAR(start_date) AS Yr, 
        COUNT(*)/(COUNT(DISTINCT(DAY(start_date)))) AS Avg_Daily_Trips
FROM trips
GROUP BY Yr, Mo;

# view new table 

SELECT * 
FROM working_table1;

# getting total number of trips in the year 2017 broken down by membership status (member/non-member)

SELECT is_member, COUNT(*)
FROM trips 
WHERE YEAR(start_date) = 2017
GROUP BY (is_member);

# getting percentage of total trips by members for the year 2017 broken down by month

SELECT MONTH(start_date) AS Month, ((SUM(is_member))/COUNT(*))*100 AS Member_Percent
FROM Trips
WHERE YEAR(start_date) = 2017
GROUP BY Month;

## Notes: demand for Bixi bikes are at its peak during the summer months, specifically during the month of July (and Aug) over both 2016 and 2017.

##      When we look at the percentage of members throughout the year, we see that the months with the highest overall demand (July and Aug) 
## 		see a decrease in the percentage of trips associated with member status, which shows us the demand for Bixi bikes amongst its non-member users is at its highest in July and August. 
## 		To try and convert non-members to members, bixi could try offering a promotion to non-members during the month of June. The promotion would need to have an expiry date prior to peak demand, 
## 		therefore the date non-members would need to claim the promo by should be around the end of June, say June 30th. The reasoning for this timing is that from June to July we see the percent of 
## 		non-member trips increase by 4.4 percetage points from June to July. We see a very similar change from August to September, however rather than an increase, we see the non-member percentage of trips
##      decrease by roughly 4.5 percentage points from August to September. To capture as many non-members as possible, we would want to offer the promotion just before we hit their peak season, being July and Aug.

# get top 5 most popular starting stations
# Top 5 are Mackay, Metro Mont-Royal, Metro Place-des-Arts, Metro Laurier, Metro Peel (generated from below code)

SELECT s.name, COUNT(*) AS number_of_trips
FROM trips AS t
JOIN stations AS s ON t.start_station_code = s.code
GROUP BY s.name 
ORDER BY number_of_trips DESC
LIMIT 5;

# getting top 5 starting stations but using a subquery in order to try and shorten run time and make my code more efficient 

SELECT s.name, t.num_of_trips
FROM 
	(SELECT start_station_code, COUNT(*) AS num_of_trips
     FROM trips
     GROUP BY start_station_code) AS t
JOIN stations AS s
ON t.start_station_code = s.code
ORDER BY t.num_of_trips DESC
LIMIT 5;

# run time decreased by roughly 20 seconds using the above subquery to retrieve top 5 starting stations in MTL
 
# looking at the most popular station, Mackay, then looking at distrubution of starts and ends throughout the day 

SELECT *
FROM stations
WHERE name = 'Mackay / de Maisonneuve';

# output for below code: distribution for starts: evening 36,781 // afternoon 30,718 // morning 17,384 // night 12,267

SELECT 
	CASE
       WHEN HOUR(start_date) BETWEEN 7 AND 11 THEN "morning"
       WHEN HOUR(start_date) BETWEEN 12 AND 16 THEN "afternoon"
       WHEN HOUR(start_date) BETWEEN 17 AND 21 THEN "evening"
       ELSE "night"
	END AS "time_of_day",
    COUNT(*) AS num_of_starts
FROM trips
WHERE start_station_code=6100
GROUP BY time_of_day
ORDER BY num_of_starts DESC;

# output for below code: distribution of ends: evening 31,983 // afternoon 30,429 // morning 26,390 // night 10,326

SELECT 
	CASE
       WHEN HOUR(end_date) BETWEEN 7 AND 11 THEN "morning"
       WHEN HOUR(end_date) BETWEEN 12 AND 16 THEN "afternoon"
       WHEN HOUR(end_date) BETWEEN 17 AND 21 THEN "evening"
       ELSE "night"
	END AS "time_of_day",
    COUNT(*) AS num_of_ends
FROM trips
WHERE end_station_code=6100
GROUP BY time_of_day
ORDER BY num_of_ends DESC;


# NOTES: starts and ends are distributed very similarly throught the day. for station mackay, trips are most frequent in the evening for both starts and ends,
# followed by afternoon, morning, and lastly night time trips for both starts and ends are the least frequent. We do see that starts in the morning are a lot less frequent
# than ends in the morning, however the order of frequency for time of day is the same for start and end times.

# Mackays proximity to univeristies and offices/businesses (high student and working professional population) likely drives up the number of trips ending in the morning
# relative to trips starting there in the morning  

# writing a query that counts the number of starting trips per station.

SELECT t.start_station_code, s.name, t.num_of_starts
FROM (SELECT start_station_code, COUNT(*) AS num_of_starts
	  FROM trips 
      GROUP BY start_station_code) AS t
JOIN stations AS s
ON t.start_station_code = s.code ;

## getting the count, for each station, the number of round trips

SELECT s.name, t.num_round_trips
FROM (SELECT start_station_code, end_station_code, COUNT(*) AS num_round_trips 
	  FROM trips
      WHERE start_station_code = end_station_code
      GROUP BY start_station_code, end_station_code) AS t 
JOIN stations AS s 
ON t.start_station_code = s.code ;

# getting the fraction of round trips (out of the total number of starting trips) for each station

SELECT s.name, (rt.num_round_trips/t.num_of_starts) AS rt_share_of_trips 
FROM (SELECT start_station_code, COUNT(*) AS num_of_starts
	  FROM trips 
      GROUP BY start_station_code) AS t
JOIN stations AS s 
	ON t.start_station_code = s.code 
JOIN (SELECT start_station_code, end_station_code, COUNT(*) AS num_round_trips 
	  FROM trips
      WHERE start_station_code = end_station_code
      GROUP BY start_station_code, end_station_code) AS rt
	ON t.start_station_code = rt.start_station_code
GROUP BY s.name;

# getting stations with at least 500 trips originating from them , that also have at least 10% of their trips as round trips, sorting by fraction of roundtrips

SELECT s.name, (rt.num_round_trips/t.num_of_starts) AS rt_share_of_trips 
FROM (SELECT start_station_code, COUNT(*) AS num_of_starts
	  FROM trips 
      GROUP BY start_station_code
      HAVING num_of_starts >=500) AS t
JOIN stations AS s 
	ON t.start_station_code = s.code 
JOIN (SELECT start_station_code, end_station_code, COUNT(*) AS num_round_trips 
	  FROM trips
      WHERE start_station_code = end_station_code
      GROUP BY start_station_code, end_station_code) AS rt
	ON t.start_station_code = rt.start_station_code
GROUP BY s.name
HAVING rt_share_of_trips >= 0.1
ORDER BY rt_share_of_trips DESC;

# Notes: I expect to see a high fraction of round trips in areas of the city located in leisure areas / tourist attractions that people travel to 
# to specifically ride their bikes (e.g. parks) or in areas with fewer stations overall. tourists and those looking for recreational outdoor
# facilities are more likely to use a bike for leisure purposes and return to the same start station, and bixi users that have fewer other 
# stations around them are likely to end their trip at the same location. 