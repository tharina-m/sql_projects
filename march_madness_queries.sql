###############################
# 2024 MARCH MADNESS: QUERIES #
###############################

USE wbball_2024;

# QUERY 1: Which matches were an upset? (Want to know if a match was an upset or not, so add that column) 
# An upset is defined when the lower seed beats the higher seed. 
#(Lower seed is high numbers, high seeds are low numbers in this case
# aka a team wants to be ranked #1 cause that’s a high seed)

# Creating a view with information on matches, focus on joining necessary tables and calculatinf total points scored by each team per match 
CREATE VIEW match_info AS 
    -- Calculate total points scored by each team per match
WITH team_points AS (
    SELECT ps.match_id, p.team_id, SUM(ps.points) AS total_points
    FROM player_stats AS ps
    INNER JOIN players AS p 
		ON ps.player_id = p.player_id
    GROUP BY ps.match_id, p.team_id
)
SELECT tp.match_id, t.name AS team_name, tp.team_id,t.ncaa_seed, tp.total_points,
    CASE 
        WHEN ht.team_id = tp.team_id THEN 'Home'
        WHEN at.team_id = tp.team_id THEN 'Away'
    END AS home_away
FROM team_points AS tp
INNER JOIN matches AS m 
	ON tp.match_id = m.match_id
INNER JOIN home_teams AS ht 
	ON m.home_team_id = ht.home_team_id
INNER JOIN away_teams AS at 
    ON m.away_team_id = at.away_team_id
INNER JOIN teams AS t 
	ON tp.team_id = t.team_id;
    
# Ranking teams 
WITH result AS (
    -- Rank teams within each match based on their total points
	SELECT match_id, team_id, team_name, ncaa_seed, total_points, 
    RANK() OVER (PARTITION BY match_id ORDER BY total_points DESC) AS match_rank
    FROM match_info 
), 
winning AS (
    -- Selecting winning team for each match
	SELECT match_id, team_id AS winning_team_id, ncaa_seed AS winning_seed
    FROM result
    WHERE match_rank = 1
),
losing AS (
    -- Selecting losing team for each match
	SELECT match_id, team_id AS losing_team_id, ncaa_seed AS losing_seed
    FROM result
    WHERE match_rank = 2
)
SELECT w.match_id, t.name AS team_name, w.winning_seed, l.losing_seed,
	    -- Calculating and categorizing to upsets, no upsets, or if both teams in match had the same seed
    CASE
		WHEN w.winning_seed > l.losing_seed THEN 'Upset'
		WHEN w.winning_seed < l.losing_seed THEN 'NO Upset'
		WHEN w.winning_seed = l.losing_seed THEN 'Same Seed'
	END as upset
FROM winning AS w
LEFT JOIN losing AS l
	ON w.match_id = l.match_id
LEFT JOIN teams AS t
	ON w.winning_team_id = t.team_id;


# QUERY 2: Do above average height players score more points? Have more assists? Have more rebounds?

-- Calculating average height of players
SELECT ROUND(AVG(height),0) AS avg_ht
FROM players;  -- Average height is 72

-- CTE to sum up player statistics by player ID (total points, rebounds, and assists)
WITH player_points AS (
	SELECT ps.player_id, CONCAT(p.first_name, ' ',p.last_name) AS full_name, p.height, SUM(ps.points) AS sum_points, SUM(ps.rebounds) AS sum_rebounds, SUM(ps.assists) AS sum_assists
    FROM player_stats AS ps
    LEFT JOIN players AS p
		ON ps.player_id = p.player_id
	GROUP BY ps.player_id, full_name, p.height
),
average_height AS (
	SELECT ROUND(AVG(height),0) AS avg_height
    FROM players
)
-- Categorize players based on their height compared to the average height
SELECT 
	CASE 
		WHEN height < (SELECT avg_height FROM average_height) THEN 'Below Average'
		WHEN height > (SELECT avg_height FROM average_height) THEN 'Above Average'
		ELSE 'Average'
	END AS height_category,
	SUM(sum_points) AS total_points,
    SUM(sum_rebounds) AS total_rebounds,
    SUM(sum_assists) AS total_assists,
    COUNT(player_id) AS player_count
FROM player_points 
GROUP BY height_category
ORDER BY player_count DESC;


# QUERY 3: CREATE A TORUNAMENT HIGHLIGHTS TABLE: player with most points, most assists, most rebounds, most minutes player!
# include player_id, players name (first and last), total amount of points, total amount of assists, total amout of rebounds, total min played
# and the rank for each of those stats

-- Creating temporary table to store top statistics per player
CREATE TEMPORARY TABLE top_stats AS
	SELECT ps.player_id,  CONCAT(p.first_name, ' ',p.last_name) AS full_name,  SUM(ps.points) AS total_points, SUM(ps.rebounds) AS total_rebounds, SUM(ps.assists) AS total_assists, SUM(ps.min_played) AS total_min,
		RANK() OVER(ORDER BY SUM(ps.points) DESC) AS points_rank,
        RANK() OVER(ORDER BY SUM(ps.rebounds) DESC) AS rebounds_rank,
        RANK() OVER(ORDER BY SUM(ps.assists) DESC) AS assists_rank,
        RANK() OVER(ORDER BY SUM(ps.min_played) DESC) AS mins_rank
    FROM player_stats AS ps
    LEFT JOIN players AS p
		ON ps.player_id = p.player_id
    GROUP BY ps.player_id, full_name;

-- Select player/players with the highest points, rebounds, assists, or minutes played
SELECT *
FROM top_stats
WHERE points_rank = 1 OR rebounds_rank = 1 OR assists_rank = 1 OR mins_rank = 1;

# QUERY 4: For positions, maybe which positions tend to play for the longest time on court?

-- Select position name, total minutes played, and rank for each position based on total minutes played
SELECT pos.name AS position_name, SUM(ps.min_played) AS total_mins, 
	RANK() OVER(ORDER BY SUM(ps.min_played) DESC) AS mins_rank
FROM player_stats AS ps
INNER JOIN players AS p
	ON ps.player_id = p.player_id
INNER JOIN positions AS pos
	ON p.position_id = pos.position_id
GROUP BY position_name
ORDER BY total_mins DESC;

