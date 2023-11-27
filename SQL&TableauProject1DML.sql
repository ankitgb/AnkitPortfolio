/***********************************************
**      MSc Applied Data Science
**     DATA ENGINEERING PLATFORMS 
** File:   Final Project DML
** Desc:   Loading Data into Tables
** Auth:   Naoki Tsumoto, Roselyn Rozario, Ankit Gubiligari, Nakul Vadlamudi 
** Group:  4
************************************************/

-- -----------------------------------------------------
-- Enable File Load and Updates
-- -----------------------------------------------------
SET SQL_SAFE_UPDATES = 0;
SET GLOBAL local_infile = 1;
SHOW VARIABLES LIKE 'local_infile';
SHOW VARIABLES LIKE "secure_file_priv";

-- -----------------------------------------------------
-- Select Database
-- -----------------------------------------------------
USE teamproject;

-- -----------------------------------------------------
-- Temporary Table - `TempPlayers`
-- -----------------------------------------------------
# Drop the existing temporary table
DROP TEMPORARY TABLE IF EXISTS TempPlayers;

# Create a new temporary table based on the structure of Countries
CREATE TEMPORARY TABLE TempPlayers (
    player_id INT,
    name_first VARCHAR(255),
    name_last VARCHAR(255),
    hand CHAR(1),
    dob DATE,
    ioc CHAR(3),
    height INT,
    wikidata_id VARCHAR(255)
);

# Load Data into the Temporary Table
LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\atp_players_till_2022.csv'
INTO TABLE TempPlayers
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 LINES
(
    player_id, 
    name_first, 
    name_last, 
    hand, 
    @dob_value, 
    ioc, 
    @height_value, 
    wikidata_id
)
SET height = CASE 
    WHEN @height_value = '' THEN NULL 
    ELSE @height_value 
END,
dob = CASE 
    WHEN @dob_value LIKE '%0000.0' THEN NULL
    WHEN @dob_value = '' THEN NULL 
    ELSE @dob_value 
END;

-- -----------------------------------------------------
-- Importing Data - `Countries` Table
-- -----------------------------------------------------
INSERT INTO Countries (ioc)
SELECT DISTINCT ioc FROM TempPlayers
WHERE ioc NOT IN (SELECT ioc FROM Countries);

-- -----------------------------------------------------
-- Importing Data - `Players` Table
-- -----------------------------------------------------
INSERT INTO Players (player_id, name_first, name_last, hand, dob, country_id, height, wikidata_id)
SELECT 
    tp.player_id,
    tp.name_first,
    tp.name_last,
    tp.hand,
    tp.dob,
    c.country_id,
    tp.height,
    tp.wikidata_id
FROM TempPlayers AS tp
JOIN Countries AS c ON tp.ioc = c.ioc;

# Drop the temporary table
DROP TEMPORARY TABLE TempPlayers;

-- -----------------------------------------------------
-- Importing Data - `Tournaments` Table
-- -----------------------------------------------------

# Drop the existing temporary table
DROP TEMPORARY TABLE IF EXISTS TempTournaments;

# Create a new temporary table based on the structure of Tournaments
CREATE TEMPORARY TABLE TempTournaments LIKE Tournaments;

# Remove the primary key or unique constraint from the temporary table
ALTER TABLE TempTournaments DROP PRIMARY KEY;

# Load Data into the Temporary Table
LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\atp-matches-till-2022_match_id.csv'
INTO TABLE TempTournaments
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 LINES
(
    @dummy,
    tourney_id,
    tourney_name,
    surface,
    draw_size,
    tourney_level,
    tourney_date,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy
);

# Insert unique data into the Tournaments table
INSERT IGNORE INTO Tournaments
SELECT DISTINCT * FROM TempTournaments;

# Drop the temporary table
DROP TEMPORARY TABLE TempTournaments;

-- -----------------------------------------------------
-- Importing Data - `Matches` Table
-- -----------------------------------------------------
LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\atp-matches-till-2022_match_id.csv'
INTO TABLE Matches 
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 LINES 
(
	match_id,
    tourney_id,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    match_num,
    winner_id,
    @winner_seed_value,
    winner_entry,
    winner_name,
    winner_hand,
    @winner_ht_value,
    winner_ioc,
    @winner_age_value,
    loser_id,
    @loser_seed_value,
    loser_entry,
    loser_name,
    loser_hand,
    @loser_ht_value,
    loser_ioc,
    @loser_age_value,
    score,
    best_of,
    round,
    @minutes_value,
    @w_ace_value,
    @w_df_value,
    @w_svpt_value,
    @w_1stIn_value,
    @w_1stWon_value,
    @w_2ndWon_value,
    @w_SvGms_value,
    @w_bpSaved_value,
    @w_bpFaced_value,
    @l_ace_value,
    @l_df_value,
    @l_svpt_value,
    @l_1stIn_value,
    @l_1stWon_value,
    @l_2ndWon_value,
    @l_SvGms_value,
    @l_bpSaved_value,
    @l_bpFaced_value,
    @winner_rank_value,
    @winner_rank_points_value,
    @loser_rank_value,
    @loser_rank_points_value    
)
SET 
winner_seed = CASE 
    WHEN @winner_seed_value = '' THEN NULL 
    ELSE @winner_seed_value 
END,
winner_ht = CASE 
    WHEN @winner_ht_value = '' THEN NULL 
    ELSE @winner_ht_value 
END,
winner_age = CASE 
    WHEN @winner_age_value = '' THEN NULL 
    ELSE @winner_age_value 
END,
loser_seed = CASE 
    WHEN @loser_seed_value = '' THEN NULL 
    ELSE @loser_seed_value 
END,
loser_ht = CASE 
    WHEN @loser_ht_value = '' THEN NULL 
    ELSE @loser_ht_value 
END,
loser_age = CASE 
    WHEN @loser_age_value = '' THEN NULL 
    ELSE @loser_age_value 
END,
minutes = CASE 
    WHEN @minutes_value = '' THEN NULL 
    ELSE @minutes_value 
END,
w_ace = CASE 
    WHEN @w_ace_value = '' THEN NULL 
    ELSE @w_ace_value 
END,
w_df = CASE 
    WHEN @w_df_value = '' THEN NULL 
    ELSE @w_df_value 
END,
w_svpt = CASE 
    WHEN @w_svpt_value = '' THEN NULL 
    ELSE @w_svpt_value 
END,
w_1stIn = CASE 
    WHEN @w_1stIn_value = '' THEN NULL 
    ELSE @w_1stIn_value 
END,
w_1stWon = CASE 
    WHEN @w_1stWon_value = '' THEN NULL 
    ELSE @w_1stWon_value 
END,
w_2ndWon = CASE 
    WHEN @w_2ndWon_value = '' THEN NULL 
    ELSE @w_2ndWon_value 
END,
w_SvGms = CASE 
    WHEN @w_SvGms_value = '' THEN NULL 
    ELSE @w_SvGms_value 
END,
w_bpSaved = CASE 
    WHEN @w_bpSaved_value = '' THEN NULL 
    ELSE @w_bpSaved_value 
END,
w_bpFaced = CASE 
    WHEN @w_bpFaced_value = '' THEN NULL 
    ELSE @w_bpFaced_value 
END,
l_ace = CASE 
    WHEN @l_ace_value = '' THEN NULL 
    ELSE @l_ace_value 
END,
l_df = CASE 
    WHEN @l_df_value = '' THEN NULL 
    ELSE @l_df_value 
END,
l_svpt = CASE 
    WHEN @l_svpt_value = '' THEN NULL 
    ELSE @l_svpt_value 
END,
l_1stIn = CASE 
    WHEN @l_1stIn_value = '' THEN NULL 
    ELSE @l_1stIn_value 
END,
l_1stWon = CASE 
    WHEN @l_1stWon_value = '' THEN NULL 
    ELSE @l_1stWon_value 
END,
l_2ndWon = CASE 
    WHEN @l_2ndWon_value = '' THEN NULL 
    ELSE @l_2ndWon_value 
END,
l_SvGms = CASE 
    WHEN @l_SvGms_value = '' THEN NULL 
    ELSE @l_SvGms_value 
END,
l_bpSaved = CASE 
    WHEN @l_bpSaved_value = '' THEN NULL 
    ELSE @l_bpSaved_value 
END,
l_bpFaced = CASE 
    WHEN @l_bpFaced_value = '' THEN NULL 
    ELSE @l_bpFaced_value 
END,
winner_rank = CASE 
    WHEN @winner_rank_value = '' THEN NULL 
    ELSE @winner_rank_value 
END,
winner_rank_points = CASE 
    WHEN @winner_rank_points_value = '' THEN NULL 
    ELSE @winner_rank_points_value 
END,
loser_rank = CASE 
    WHEN @loser_rank_value = '' THEN NULL 
    ELSE @loser_rank_value 
END,
loser_rank_points = CASE 
    WHEN @loser_rank_points_value = '' THEN NULL 
    ELSE @loser_rank_points_value 
END;

-- -----------------------------------------------------
-- Importing Data - `Rankings` Table
-- -----------------------------------------------------
LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\atp_rankings_till_2022_ranking_id.csv'
INTO TABLE Rankings 
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
( 
	ranking_id, 
    @ranking_date, 
    `rank`, 
    player_id, 
    @points_value 
)
SET 
ranking_date = STR_TO_DATE(@ranking_date, '%Y%m%d'),
points = CASE 
	WHEN @points_value = ' ' OR @points_value = '' OR @points_value REGEXP '^[^0-9]+$' THEN NULL 
	ELSE CAST(@points_value AS SIGNED) 
END;

-- -----------------------------------------------------
-- Importing Data - `players_matches` Table
-- -----------------------------------------------------
# Populating the players_matches table with winners and losers from the Matches table

# Insert winners' data into the players_matches table
INSERT INTO players_matches (player_id, match_id)
SELECT winner_id, match_id FROM Matches;

# Insert losers' data into the players_matches table
INSERT INTO players_matches (player_id, match_id)
SELECT loser_id, match_id FROM Matches;
