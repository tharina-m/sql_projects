#######################################
# MARCH MADNESS: TABLES & DATA IMPORT #
#######################################

# Creating a schema or database called wball_2024 (stands for womens basketball 2024)
CREATE DATABASE IF NOT EXISTS wbball_2024;
USE wbball_2024;

#DROP DATABASE IF EXISTS wbball_2024;

# creating teams table (we included 16 teams, the sweet 16)
CREATE TABLE IF NOT EXISTS teams 
(
team_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY, #id can only be positive
name VARCHAR(150),
head_coach_first_name VARCHAR(300),
head_coach_last_name VARCHAR(300),
conference VARCHAR(20),
year_founded CHAR(4), 
#couldn't use YEAR as the data type because YEAR only goes from 1901 to 2155, and some bball teams were founded earlier than 1901
ncaa_titles TINYINT,
final_four_appear TINYINT,
city VARCHAR(250),
state CHAR(2), #state abbreviations always have 2 characters
ncaa_seed TINYINT

);

-- Trigger for State Abbreviation is inputted as 2 characters 
DELIMITER //

CREATE TRIGGER validate_state_abbreviation
BEFORE INSERT ON teams
FOR EACH ROW
BEGIN
    IF LENGTH(NEW.state) != 2 THEN
        SIGNAL SQLSTATE 'HY000' SET MESSAGE_TEXT = 'State abbreviation must have exactly 2 characters.';
    END IF;
END;
//

DELIMITER ;

# creating positions table for different positions a player can play at - look up table 1
CREATE TABLE IF NOT EXISTS positions
(
position_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
name VARCHAR(150)

);

# creating classes table for the player's grade in college - look up table 2
CREATE TABLE IF NOT EXISTS classes
(
class_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
name VARCHAR(150)

);


# creating players table 
CREATE TABLE IF NOT EXISTS players 
(
player_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY, #id can only be positive
team_id INT UNSIGNED, 
first_name VARCHAR(250),
last_name VARCHAR(250),
position_id INT UNSIGNED, #look up table
class_id INT UNSIGNED, #look up table
height CHAR(5), 

FOREIGN KEY (team_id) REFERENCES teams(team_id)
ON UPDATE CASCADE
ON DELETE CASCADE,

FOREIGN KEY (position_id) REFERENCES positions(position_id)
ON UPDATE CASCADE
ON DELETE CASCADE,

FOREIGN KEY (class_id) REFERENCES classes(class_id)
ON UPDATE CASCADE
ON DELETE CASCADE


);

CREATE INDEX team_id_index
ON players (team_id);

CREATE INDEX position_id_index
ON players (position_id);

-- Trigger to Check if Team ID exists before inserting

DELIMITER //

CREATE TRIGGER check_team_membership
BEFORE INSERT ON players
FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT 1 
                    FROM teams 
                    WHERE team_id = NEW.team_id) THEN
        SIGNAL SQLSTATE 'HY000' SET MESSAGE_TEXT = 'Team ID does not exist.';
    END IF;
END;
//

DELIMITER ;

-- Trigger to Check if Position ID exists 

DELIMITER //

CREATE TRIGGER check_position_id
BEFORE INSERT ON players
FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT 1 
                    FROM positions 
                    WHERE position_id = NEW.position_id) THEN
        SIGNAL SQLSTATE 'HY000' SET MESSAGE_TEXT = 'Position ID does not exist.';
    END IF;
END;
//

DELIMITER ;

-- Trigger to Check if Class ID exissts

DELIMITER //

CREATE TRIGGER check_class_id
BEFORE INSERT ON players
FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT 1 
                    FROM classes 
                    WHERE class_id = NEW.class_id) THEN
        SIGNAL SQLSTATE 'HY000' SET MESSAGE_TEXT = 'Class ID does not exist.';
    END IF;
END;
//

DELIMITER ;

# creating home_teams table with information on the "home" team during a match
CREATE TABLE IF NOT EXISTS home_teams 
(
home_team_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY, #id can only be positive
team_id INT UNSIGNED, 
turnovers TINYINT,
steals TINYINT,
free_throw_percent DECIMAL, 
three_pointer_percent DECIMAL,
field_goal_percent DECIMAL, 

FOREIGN KEY (team_id) REFERENCES teams(team_id)
ON UPDATE CASCADE
ON DELETE CASCADE

);

CREATE INDEX team_id_index_home_teams
ON home_teams (team_id);

# creating away_teams table with information on the "away" team during a match
CREATE TABLE IF NOT EXISTS away_teams 
(
away_team_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY, #id can only be positive
team_id INT UNSIGNED, 
turnovers TINYINT,
steals TINYINT,
free_throw_percent DECIMAL,
three_pointer_percent DECIMAL, 
field_goal_percent DECIMAL, 

FOREIGN KEY (team_id) REFERENCES teams(team_id)
ON UPDATE CASCADE
ON DELETE CASCADE

);

CREATE INDEX team_id_index_away_teams
ON away_teams (team_id);

# creating matches table
CREATE TABLE IF NOT EXISTS matches 
(
match_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY, #id can only be positive
home_team_id INT UNSIGNED, 
away_team_id INT UNSIGNED,
date_time DATETIME,

FOREIGN KEY (home_team_id) REFERENCES home_teams(home_team_id)
ON UPDATE CASCADE
ON DELETE CASCADE,

FOREIGN KEY (away_team_id) REFERENCES away_teams(away_team_id)
ON UPDATE CASCADE
ON DELETE CASCADE

);

CREATE INDEX home_team_id_index
ON matches (home_team_id);

CREATE INDEX away_team_id_index
ON matches (away_team_id);


DELIMITER //

-- Trigger for Check if teams in match exist 
CREATE TRIGGER validate_match_teams
BEFORE INSERT ON matches
FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT 1 
					FROM home_teams 
                    WHERE home_team_id = NEW.home_team_id) THEN
        SIGNAL SQLSTATE 'HY000' SET MESSAGE_TEXT = 'Home team does not exist.';
    END IF;
    IF NOT EXISTS (SELECT 1 
					FROM away_teams 
                    WHERE away_team_id = NEW.away_team_id) THEN
        SIGNAL SQLSTATE 'HY000' SET MESSAGE_TEXT = 'Away team does not exist.';
    END IF;
END;
//

DELIMITER ; 


-- Trigger to prevent duplicate matches
DELIMITER // 

CREATE TRIGGER prevent_duplicate_matches
BEFORE INSERT ON matches
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 
				FROM matches
				WHERE home_team_id = NEW.home_team_id 
					AND away_team_id = NEW.away_team_id 
                    AND date_time = NEW.date_time) THEN
        SIGNAL SQLSTATE 'HY000' SET MESSAGE_TEXT = 'Duplicate match found.';
    END IF;
END;
//

DELIMITER ; 

# creating player_stats table with information on player's statistics per match 
CREATE TABLE IF NOT EXISTS player_stats 
(
player_id INT UNSIGNED AUTO_INCREMENT, #id can only be positive
match_id INT UNSIGNED, 
min_played INT UNSIGNED, 
rebounds TINYINT,
assists TINYINT, 
points SMALLINT,

PRIMARY KEY(player_id, match_id), # composite primary key because table representing statistics per player per match 

FOREIGN KEY (player_id) REFERENCES players(player_id)
ON UPDATE CASCADE
ON DELETE CASCADE, 

FOREIGN KEY (match_id) REFERENCES matches(match_id)
ON UPDATE CASCADE
ON DELETE CASCADE

);

CREATE INDEX player_id_index
ON player_stats (player_id);

CREATE INDEX match_id_index
ON player_stats (match_id);
#################################################################

# Populating teams table
INSERT INTO teams(name, head_coach_first_name, head_coach_last_name, conference, year_founded, ncaa_titles, final_four_appear, city, state, ncaa_seed) 
VALUES 
('South Carolina', 'Dawn', 'Staley', 'SEC', 1974, 2, 6, 'Columbia', 'SC', 1),
('Indiana', 'Teri', 'Moren', 'Big Ten', 1971, 0, 0, 'Bloomington', 'IN', 4),
('Oregon St.', 'Scott', 'Rueck', 'Pac 12', 1976, 0, 1, 'Corvallis', 'OR', 3),
('Notre Dame', 'Niele', 'Ivey', 'ACC', 1977, 2, 9, 'Notre Dame', 'IN', 2),
('Texas', 'Vic', 'Shaefer', 'Big 12', 1974, 1, 3, 'Austin', 'TX', 1),
('Gonzaga', 'Lisa', 'Fortier', 'WCC', 1987, 0, 0, 'Spokane', 'WA', 4),
('NC State', 'Wes', 'Moore', 'ACC', 1974, 0, 2, 'Raleigh', 'NC', 3),
('Stanford', 'Tara', 'VanDerveer', 'Pac 12', 1896, 3, 15, 'Stanford', 'CA', 2),
('Iowa', 'Lisa', 'Bluder', 'Big Ten', 1974, 0, 3, 'Iowa City', 'IA', 1),
('Colorado', 'JR', 'Payne', 'Pac 12', 1975, 0, 0, 'Boulder', 'CO', 5),
('LSU', 'Kim', 'Mulkey','SEC', 1975, 1, 6, 'Baton Rouge', 'LA', 3),
('UCLA', 'Cori', 'Close', 'Pac 12', 1974, 0, 0, 'Los Angeles', 'CA', 2),
('USC', 'Lindsay', 'Gottlieb', 'Pac 12', 1976, 2, 3, 'Los Angeles', 'CA', 1),
('Baylor', 'Nicki', 'Collen','Big 12', 1974, 3, 4, 'Waco', 'TX', 5),
('UConn', 'Geno', 'Auriemma', 'ACC', 1974, 11, 23, 'Storrs', 'CT', 3),
('Duke', 'Kara', 'Lawson','ACC', 1974, 0, 4, 'Durham', 'NC', 7);

SELECT *
FROM teams;

# Populating positions table
INSERT INTO positions(name)
VALUES
('center'),
('forward'),
('guard');

# Populating classes table
INSERT INTO classes(name)
VALUES
('freshman'),
('sophmore'),
('junior'),
('senior'),
('5th year');

# Importing players, home_teams, away_teams, matches, and player_stats from CSV file (IN THE ORDER LISTED)

SELECT *
FROM teams;

SELECT *
FROM positions;

SELECT *
FROM classes;

SELECT *
FROM players;

SELECT *
FROM home_teams;

SELECT *
FROM away_teams;

SELECT *
FROM matches;

SELECT *
FROM player_stats;





