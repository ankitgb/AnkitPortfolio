/***********************************************
**      MSc Applied Data Science
**     DATA ENGINEERING PLATFORMS 
** File:   Final Project Queries
** Desc:   SQL Queries for EDA
** Auth:   Naoki Tsumoto, Roselyn Rozario, Ankit Gubiligari, Nakul Vadlamudi 
** Group:  4
************************************************/

-- -------------------------------------------------------------------------
-- Select Database
-- -------------------------------------------------------------------------
USE teamproject;

-- -------------------------------------------------------------------------
-- Investigating Player Performance on Surfaces Based on Their Country
-- -------------------------------------------------------------------------

SELECT DISTINCT surface FROM tournaments;

SELECT DISTINCT ioc FROM countries;

SELECT 
	c.ioc AS countryInitials,
    p.name_first AS firstName,
    p.name_last AS lastName,
    COUNT(a.winner_id) as winnerCount
FROM 
	countries c 
		INNER JOIN
	players p ON c.country_id = p.country_id
		INNER JOIN
	players_matches m ON p.player_id = m.player_id
		INNER JOIN
	matches a ON m.match_id = a.match_id
		INNER JOIN
	tournaments t ON a.tourney_id = t.tourney_id
GROUP BY 
    c.ioc, p.name_first, p.name_last
ORDER BY 
    c.ioc, COUNT(a.winner_id) DESC;

# ALT
SELECT 
    c.ioc AS countryInitials,
    COUNT(a.winner_id) AS winnerCount
FROM 
    countries c 
        INNER JOIN players p ON c.country_id = p.country_id
        INNER JOIN players_matches m ON p.player_id = m.player_id
        INNER JOIN matches a ON m.match_id = a.match_id
        INNER JOIN tournaments t ON a.tourney_id = t.tourney_id
GROUP BY 
    c.ioc
ORDER BY 
    COUNT(a.winner_id) DESC;

SELECT 
	t.surface,
	p.name_first AS firstName,
    p.name_last AS lastName,
    c.ioc AS countryInitials,
    COUNT(a.winner_id) as winnerCount
FROM 
	countries c 
		INNER JOIN
	players p ON c.country_id = p.country_id
		INNER JOIN
	players_matches m ON p.player_id = m.player_id
		INNER JOIN
	matches a ON m.match_id = a.match_id
		INNER JOIN
	tournaments t ON a.tourney_id = t.tourney_id
GROUP BY t.surface, p.name_first, p.name_last, c.ioc;

# ALT
SELECT 
    t.surface,
    COUNT(a.winner_id) AS winnerCount
FROM 
    countries c 
        INNER JOIN players p ON c.country_id = p.country_id
        INNER JOIN players_matches m ON p.player_id = m.player_id
        INNER JOIN matches a ON m.match_id = a.match_id
        INNER JOIN tournaments t ON a.tourney_id = t.tourney_id
GROUP BY 
    t.surface
ORDER BY 
    COUNT(a.winner_id) DESC;

# Group the players’ countries and count that group’s wins for each surface

SELECT 
    t.surface AS Surface,
    c.ioc AS CountryInitials,
    COUNT(a.winner_id) AS WinnerCount
FROM 
    tournaments t
    INNER JOIN matches a ON t.tourney_id = a.tourney_id
    INNER JOIN players_matches m ON a.match_id = m.match_id
    INNER JOIN players p ON m.player_id = p.player_id
    INNER JOIN countries c ON p.country_id = c.country_id
GROUP BY 
    t.surface, c.ioc
ORDER BY 
    t.surface, COUNT(a.winner_id) DESC;
    
-- ----------------------------------------------------------------------------------------
-- Investigating Characteristics' (e.g., dominant hand used, age, mentality) Impact on Player Performance
-- ----------------------------------------------------------------------------------------

# Winning probability by hand

SELECT m.winner_hand,
CONCAT(ROUND(100.0*COUNT(*)/(SELECT COUNT(*) FROM matches),2),'%') AS winningProbability
FROM players p 
JOIN matches m 
ON p.player_id=m.winner_id
WHERE m.winner_hand <> ''
GROUP BY m.winner_hand;

-- If the player is right handed, he is more likely to win the match. This is purely based on correlation and hence does not imply causation.

# Winning probability by age group

SELECT 
	CASE
		WHEN m.winner_age BETWEEN 13 AND 19 THEN 'Teen'
		WHEN m.winner_age BETWEEN 20 AND 29 THEN '20s'
		WHEN m.winner_age BETWEEN 30 AND 39 THEN '30s'
		WHEN m.winner_age BETWEEN 40 AND 49 THEN '40s'
		WHEN m.winner_age BETWEEN 50 AND 59 THEN '50s'
		ELSE 'Other'
	END AS age_group,
    CONCAT(ROUND(100.0*COUNT(*)/(SELECT COUNT(*) FROM matches),2),'%') AS winningProbability
FROM players p 
JOIN matches m 
ON p.player_id=m.winner_id
GROUP BY age_group
ORDER BY COUNT(*)/(SELECT COUNT(*) FROM matches) DESC;

-- If the player is in 20s, they have the highest probability to win followed by those in 30s.

# Analysis of Player Height on Rank and Amount of Points Scored:
SELECT a.player_id,
       a.name_first,
       a.name_last,
       MAX(a.height) AS height,
       MAX(b.`rank`) AS player_rank,
       MAX(b.points) AS points
FROM teamproject.players a 
JOIN teamproject.rankings b ON a.player_id = b.player_id
WHERE a.height IS NOT NULL
GROUP BY a.player_id, a.name_first, a.name_last
ORDER BY MAX(a.height) DESC;

# Player's Mentality Analysis of Score, Round, and Minutes Played:
SELECT a.player_id,
       a.name_first,
       a.name_last,
       MAX(d.best_of) AS Number_of_Sets,
       MAX(d.score) AS Score,
       MAX(d.round) AS Round,
       MAX(d.minutes) AS Minutes
FROM teamproject.players a 
JOIN teamproject.players_matches c ON a.player_id = c.player_id
JOIN teamproject.matches d ON c.match_id = d.match_id
WHERE d.Minutes is not NULL
GROUP BY a.player_id, a.name_first, a.name_last
ORDER BY MAX(d.Minutes) DESC;

# Winner and Loser Age vs. Tourney Level
SELECT a.player_id,
       a.name_first,
       a.name_last,
       MAX(d.winner_name) AS WinnerName,
       MAX(d.winner_age) AS WinnerAge,
        MAX(d.loser_name) AS LoserName,
       MAX(d.loser_age) AS LoserAge,
       MAX(e.tourney_level) AS TourneyLevel
FROM teamproject.players a 
JOIN teamproject.players_matches c ON a.player_id = c.player_id
JOIN teamproject.matches d ON c.match_id = d.match_id
JOIN teamproject.Tournaments e ON d.tourney_id = e.tourney_id
WHERE d.winner_age is not Null AND d.loser_age is not Null
GROUP BY a.player_id, a.name_first, a.name_last;

-- ----------------------------------------------------------------------------------------
-- Player's Game Performance - How Players Win Points In A Game
-- ----------------------------------------------------------------------------------------

# Due to the extensive computational load, separate tables for winners and losers are created to divide and manage the calculations more efficiently

# Remove existing WinnerStats view if it exists
DROP VIEW IF EXISTS WinnerStats;

# Create a view for winners' statistics
CREATE VIEW WinnerStats AS
SELECT 
    p.player_id,
    p.name_first,
    p.name_last,
    c.ioc AS country,
    SUM(COALESCE(m.w_ace, 0)) AS total_aces, -- Total aces achieved by the winner
    SUM(COALESCE(m.w_df, 0)) AS total_double_faults, -- Total double faults made by the winner
    SUM(COALESCE(m.w_svpt, 0)) AS total_service_points -- Total service points played by the winner
FROM 
    Matches m
    JOIN Players p ON m.winner_id = p.player_id
    JOIN Countries c ON p.country_id = c.country_id
GROUP BY 
    p.player_id, p.name_first, p.name_last, c.ioc;

# Remove existing LoserStats view if it exists
DROP VIEW IF EXISTS LoserStats;

# Create a view for losers' statistics
CREATE VIEW LoserStats AS
SELECT 
    p.player_id,
    p.name_first,
    p.name_last,
    c.ioc AS country,
    SUM(COALESCE(m.l_ace, 0)) AS total_aces, -- Total aces achieved by the loser
    SUM(COALESCE(m.l_df, 0)) AS total_double_faults, -- Total double faults made by the loser
    SUM(COALESCE(m.l_svpt, 0)) AS total_service_points -- Total service points played by the loser
FROM 
    Matches m
    JOIN Players p ON m.loser_id = p.player_id
    JOIN Countries c ON p.country_id = c.country_id
GROUP BY 
    p.player_id, p.name_first, p.name_last, c.ioc;

# Remove existing WinnerAdvancedStats view if it exists
DROP VIEW IF EXISTS WinnerAdvancedStats;

# Create a view for advanced statistics of winners
CREATE VIEW WinnerAdvancedStats AS
SELECT 
    p.player_id,
    COALESCE(SUM(m.w_bpFaced - m.w_bpSaved) / NULLIF(SUM(m.w_bpFaced), 0), 0) AS breakpoint_efficiency, -- Breakpoint efficiency for the winner
    COALESCE(SUM(m.w_1stWon + m.w_2ndWon) / NULLIF(SUM(m.w_svpt), 0), 0) AS serve_effectiveness -- Serve effectiveness for the winner
FROM 
    Matches m
    JOIN Players p ON m.winner_id = p.player_id
GROUP BY 
    p.player_id;

# Remove existing LoserAdvancedStats view if it exists
DROP VIEW IF EXISTS LoserAdvancedStats;

# Create a view for advanced statistics of losers
CREATE VIEW LoserAdvancedStats AS
SELECT 
    p.player_id,
    COALESCE(SUM(m.l_bpFaced - m.l_bpSaved) / NULLIF(SUM(m.l_bpFaced), 0), 0) AS breakpoint_efficiency, -- Breakpoint efficiency for the loser
    COALESCE(SUM(m.l_1stWon + m.l_2ndWon) / NULLIF(SUM(m.l_svpt), 0), 0) AS serve_effectiveness -- Serve effectiveness for the loser
FROM 
    Matches m
    JOIN Players p ON m.loser_id = p.player_id
GROUP BY 
    p.player_id;

# Remove existing ComprehensivePlayerStats view if it exists
DROP VIEW IF EXISTS ComprehensivePlayerStats;

# Create a comprehensive view combining all statistics
CREATE VIEW ComprehensivePlayerStats AS
SELECT 
    w.player_id,
    w.name_first,
    w.name_last,
    w.country,
    w.total_aces AS total_aces_won, -- Total aces when the player won
    l.total_aces AS total_aces_lost, -- Total aces when the player lost
    w.total_double_faults AS total_double_faults_won, -- Total double faults when the player won
    l.total_double_faults AS total_double_faults_lost, -- Total double faults when the player lost
    w.total_service_points AS total_service_points_won, -- Total service points when the player won
    l.total_service_points AS total_service_points_lost, -- Total service points when the player lost
    wa.breakpoint_efficiency AS breakpoint_efficiency_won, -- Breakpoint efficiency when the player won
    la.breakpoint_efficiency AS breakpoint_efficiency_lost, -- Breakpoint efficiency when the player lost
    wa.serve_effectiveness AS serve_effectiveness_won, -- Serve effectiveness when the player won
    la.serve_effectiveness AS serve_effectiveness_lost -- Serve effectiveness when the player lost
FROM 
    WinnerStats w
    JOIN LoserStats l ON w.player_id = l.player_id
    JOIN WinnerAdvancedStats wa ON w.player_id = wa.player_id
    JOIN LoserAdvancedStats la ON l.player_id = la.player_id;

# Check the created views
SELECT * FROM WinnerStats LIMIT 50;
SELECT * FROM LoserStats LIMIT 50;
SELECT * FROM WinnerAdvancedStats LIMIT 50;
SELECT * FROM LoserAdvancedStats LIMIT 50;
SELECT * FROM ComprehensivePlayerStats LIMIT 50;

-- ----------------------------------------------------------------------------------------
-- Impact of External Factors (e.g., seed, tournament level, etc.) on Player Performance 
-- ----------------------------------------------------------------------------------------

# Remove existing WinnerStats view if it exists
DROP VIEW IF EXISTS WinnerSeedWinningProbability;
DROP VIEW IF EXISTS LoserSeedWinningProbability;
DROP VIEW IF EXISTS WinnerEntryWinningProbability;
DROP VIEW IF EXISTS LoserEntryWinningProbability;

# Winning probability of winning players in the respective seeds
CREATE VIEW WinnerSeedWinningProbability AS
SELECT 
	CASE
		WHEN m.winner_seed BETWEEN 1 AND 10 THEN 'High'
		WHEN m.winner_seed BETWEEN 11 AND 20 THEN 'Upper Medium'
		WHEN m.winner_seed BETWEEN 21 AND 30 THEN 'Lower Medium'
		ELSE 'Low'
	END AS seedGroup,
    CONCAT(ROUND(100.0*COUNT(*)/(SELECT COUNT(*) FROM matches),2),'%') AS winningProbability
FROM players p 
JOIN matches m 
ON p.player_id=m.winner_id
GROUP BY seedGroup
ORDER BY COUNT(*)/(SELECT COUNT(*) FROM matches) DESC;

# Winning probability of losing players in the respective seeds
CREATE VIEW LoserSeedWinningProbability AS
SELECT 
	CASE
		WHEN m.loser_seed BETWEEN 1 AND 10 THEN 'High'
		WHEN m.loser_seed BETWEEN 11 AND 20 THEN 'Upper Medium'
		WHEN m.loser_seed BETWEEN 21 AND 30 THEN 'Lower Medium'
		ELSE 'Low'
	END AS seedGroup,
    CONCAT(ROUND(100.0*COUNT(*)/(SELECT COUNT(*) FROM matches),2),'%') AS winningProbability
FROM players p 
JOIN matches m 
ON p.player_id=m.loser_id
GROUP BY seedGroup
ORDER BY COUNT(*)/(SELECT COUNT(*) FROM matches) DESC;

# Winner entry's winning probability
CREATE VIEW WinnerEntryWinningProbability AS
SELECT 
	CASE
		WHEN m.winner_entry = 'Q' THEN 'Qualifier'
		WHEN m.winner_entry = 'WC' THEN 'Wild Card'
		WHEN m.winner_entry = 'LL' THEN 'Lucky Loser'
        WHEN m.winner_entry = 'PR' THEN 'Protected Ranking'
		ELSE 'Special Exempt'
	END AS entryType,
    CONCAT(ROUND(100.0*COUNT(*)/(SELECT COUNT(*) FROM matches),2),'%') AS winningProbability
FROM players p 
JOIN matches m 
ON p.player_id=m.winner_id
GROUP BY entryType
ORDER BY COUNT(*)/(SELECT COUNT(*) FROM matches) DESC;

# Losing entry's winning probability
CREATE VIEW LoserEntryWinningProbability AS
SELECT 
	CASE
		WHEN m.loser_entry = 'Q' THEN 'Qualifier'
		WHEN m.loser_entry = 'WC' THEN 'Wild Card'
		WHEN m.loser_entry = 'LL' THEN 'Lucky Loser'
        WHEN m.loser_entry = 'PR' THEN 'Protected Ranking'
		ELSE 'Special Exempt'
	END AS entryType,
    CONCAT(ROUND(100.0*COUNT(*)/(SELECT COUNT(*) FROM matches),2),'%') AS winningProbability
FROM players p 
JOIN matches m 
ON p.player_id=m.loser_id
GROUP BY entryType
ORDER BY COUNT(*)/(SELECT COUNT(*) FROM matches) DESC;

# Check the created views
SELECT * FROM WinnerSeedWinningProbability LIMIT 50;
SELECT * FROM LoserSeedWinningProbability LIMIT 50;
SELECT * FROM WinnerEntryWinningProbability LIMIT 50;
SELECT * FROM LoserEntryWinningProbability LIMIT 50;