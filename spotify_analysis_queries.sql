# Spotify Music Streaming Data Analysis
# Date: 03/20/2024
# Tharina Messeroux

/*
This SQL script provides an analysis of personal music streaming data from Spotify, focusing on various metrics such as the total number of songs streamed,
top artists and songs, listening trends over time, and periods of inactivity. The queries include counting distinct artists and songs, calculating total listening 
time, identifying peak listening days and months, and analyzing the longest gap between listening sessions. The script utilizes functions like RANK(), SUM(), and
TIMESTAMPDIFF() to answer key questions about streaming behavior and preferences.

*/
-- DROP SCHEMA spotify_wrap; 
-- DROP SCHEMA spotify_wrap; 

CREATE SCHEMA spotify_wrap; 
USE spotify_wrap; 

SELECT COUNT(*)
FROM full_streaming_history;

-- Fix date types 

ALTER TABLE full_streaming_history
MODIFY COLUMN endTime DATETIME; 

# Chaning variable names 

-- Assign new value to the variable
ALTER TABLE full_streaming_history
RENAME COLUMN endTime TO end_time; 

ALTER TABLE full_streaming_history
RENAME COLUMN artistName TO artist_name; 

ALTER TABLE full_streaming_history
RENAME COLUMN trackName TO track_name; 

ALTER TABLE full_streaming_history
RENAME COLUMN msPlayed TO ms_played;

-- START HERE 
USE spotify_wrap; 
SELECT *
FROM full_streaming_history;

-- 1. How many songs have you streamed? (Query 1)
SELECT COUNT(*)
FROM full_streaming_history;

-- I have streamed 27972 songs 

-- 2. What are your top 5 artists of all time and how many minutes have you spent listening to each artist? List the results in ranking order. (Query 2)

SELECT *
FROM full_streaming_history;

SELECT artist_name, total_time
FROM (
    SELECT artist_name, SUM(ms_played) AS total_time,
           RANK() OVER (ORDER BY SUM(ms_played) DESC) AS artist_rank
    FROM full_streaming_history
    GROUP BY artist_name
) AS ranked_artists
WHERE artist_rank <= 5;

-- My top 5 artists were Daan Junior, Amaarae, Rema, Vistoria Monet and Jugle. I have spent 80833042, 64873641, 63093533, 59888077, 59297595 ms listening to them, respectively. 

-- 3. What are your top 5 songs of all time? Make sure to include each song’s artist. (Query 3)

SELECT track_name, artist_name, total_time
FROM (
    SELECT track_name, artist_name, SUM(ms_played) AS total_time,
           RANK() OVER (ORDER BY SUM(ms_played) DESC) AS track_rank
    FROM full_streaming_history
    GROUP BY artist_name, track_name
) AS ranked_tracks
WHERE track_rank <= 5;

-- My top 5 songs of all time are Fem Voye by Joé Dwèt Filé, Big Steppa by Amaarae, Soperiye by Medjy, Dandelions - slowed + reverb by Ruth B., and Wasted Eyes by Amaarae 

-- 4. How many artists have you listened to of all time? (Query 4)

SELECT COUNT(DISTINCT artist_name)
FROM full_streaming_history;

-- I have listened to 2097 artists of all time 

-- 5. How many unique songs did you listen to in 2023? (Query 5)

SELECT *
FROM full_streaming_history;

SELECT COUNT(DISTINCT track_name)
FROM full_streaming_history
WHERE YEAR(end_time) = 2023;

-- I listened to 4320 unique songs in 2023

-- 6. How much time did you spend listening to music? Round to the nearest minute.(Query 6)

SELECT *
FROM full_streaming_history;

SELECT DISTINCT YEAR(end_time)
FROM full_streaming_history;

SELECT YEAR(end_time) AS year_listen, ROUND(SUM(ms_played) / 60000) AS total_minutes
FROM full_streaming_history
GROUP BY year_listen;

-- In 2023, I spent 41305 minutes listening to music 2023 and 8076 mins in 2024, leading to a total of 49381 minutes spent listening to music. 


-- 7. What day did you listen to the most music? How many minutes of music did you listen to? (Query 7)

SELECT *
FROM full_streaming_history;

SELECT listening_date, ROUND(total_ms / 60000) AS total_minutes
FROM (
    SELECT DATE(end_time) AS listening_date, SUM(ms_played) AS total_ms
    FROM full_streaming_history
    GROUP BY listening_date
) AS daily_totals
ORDER BY total_minutes DESC
LIMIT 1;

-- I listened to the most music on November 19, 2023 by listening to 579 minutes of music 

-- 8. What was your peak listening month? How many minutes of music did you listen to? Your query must return the name of each month (ex: 1 = January). (Query 8)

SELECT month_number,
       CASE 
           WHEN month_number = 1 THEN 'January'
           WHEN month_number = 2 THEN 'February'
           WHEN month_number = 3 THEN 'March'
           WHEN month_number = 4 THEN 'April'
           WHEN month_number = 5 THEN 'May'
           WHEN month_number = 6 THEN 'June'
           WHEN month_number = 7 THEN 'July'
           WHEN month_number = 8 THEN 'August'
           WHEN month_number = 9 THEN 'September'
           WHEN month_number = 10 THEN 'October'
           WHEN month_number = 11 THEN 'November'
           WHEN month_number = 12 THEN 'December'
       END AS month_name,
       ROUND(SUM(ms_played) / 60000) AS total_minutes
FROM (
    SELECT MONTH(end_time) AS month_number, ms_played
    FROM full_streaming_history
) AS months
GROUP BY month_number, month_name
ORDER BY total_minutes DESC
LIMIT 1;

-- My peak listening month was september. I listened to 5588 minutes of songs 

-- 9. What was your peak listening month for your top artist? How many minutes of music did you listen to? Your query must return the name of each month (ex: 1 = January). (Query 9)

WITH top_artist AS (
    SELECT artist_name
    FROM (
        SELECT artist_name, SUM(ms_played) AS total_time,
               RANK() OVER (ORDER BY SUM(ms_played) DESC) AS artist_rank
        FROM full_streaming_history
        GROUP BY artist_name
    ) AS ranked_artists
    WHERE artist_rank = 1
)

SELECT artist_name,
       month_number,
       CASE 
           WHEN month_number = 1 THEN 'January'
           WHEN month_number = 2 THEN 'February'
           WHEN month_number = 3 THEN 'March'
           WHEN month_number = 4 THEN 'April'
           WHEN month_number = 5 THEN 'May'
           WHEN month_number = 6 THEN 'June'
           WHEN month_number = 7 THEN 'July'
           WHEN month_number = 8 THEN 'August'
           WHEN month_number = 9 THEN 'September'
           WHEN month_number = 10 THEN 'October'
           WHEN month_number = 11 THEN 'November'
           WHEN month_number = 12 THEN 'December'
       END AS month_name,
       ROUND(SUM(ms_played) / 60000) AS total_minutes
FROM (
    SELECT MONTH(end_time) AS month_number, ms_played, artist_name
    FROM full_streaming_history
    WHERE artist_name IN (SELECT artist_name FROM top_artist)
) AS months
GROUP BY artist_name, month_number, month_name
ORDER BY total_minutes DESC
LIMIT 1;

-- My peak listening month for my top artist was april. I listened to 324 minutes of Daan Junior songs

-- 10.What is the longest amount of time in minutes you have spent not listening to  music? Hint: Using the MySQL 8.0 Reference Manual research DATEDIFF, 
-- TIMEDIFF, and TIMESTAMPDIFF functions to help you answer this question.(Query 10)

SELECT MAX(diff_min) AS longest_time_not_listening
FROM (
    SELECT TIMESTAMPDIFF(MINUTE, 
                         LAG(end_time) OVER (ORDER BY end_time), 
                         end_time) AS diff_min
    FROM full_streaming_history
) AS non_listening_time;

-- The longest amount of time in minutes I  have spent not listening to music is 3639