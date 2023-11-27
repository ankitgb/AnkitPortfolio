/***********************************************
**      MSc Applied Data Science
**     DATA ENGINEERING PLATFORMS 
** File:   Final Project DDL
** Desc:   Creating Tables for Dataset
** Auth:   Naoki Tsumoto, Roselyn Rozario, Ankit Gubiligari, Nakul Vadlamudi 
** Group:  4
************************************************/

-- -----------------------------------------------------
-- Select Database
-- -----------------------------------------------------
DROP DATABASE IF EXISTS teamproject;
CREATE DATABASE teamproject;
USE teamproject;

-- -----------------------------------------------------
-- Table `Countries`
-- -----------------------------------------------------
CREATE TABLE Countries (
    country_id INT AUTO_INCREMENT PRIMARY KEY,
    ioc CHAR(3)
);

-- -----------------------------------------------------
-- Table `Players`
-- -----------------------------------------------------
CREATE TABLE Players (
    player_id INT PRIMARY KEY,
    name_first VARCHAR(255),
    name_last VARCHAR(255),
    hand CHAR(1),
    dob DATE,
    country_id INT,
    height INT,
    wikidata_id VARCHAR(255),
    CONSTRAINT fk_players_countries FOREIGN KEY (country_id)
		REFERENCES Countries(country_id)
		ON DELETE NO ACTION ON UPDATE NO ACTION
);

-- -----------------------------------------------------
-- Table `Tournaments`
-- -----------------------------------------------------
CREATE TABLE Tournaments (
    tourney_id VARCHAR(255) PRIMARY KEY,
    tourney_name VARCHAR(255),
    surface VARCHAR(255),
    draw_size INT,
    tourney_level CHAR(1),
    tourney_date DATE
);

-- -----------------------------------------------------
-- Table `Matches`
-- -----------------------------------------------------
CREATE TABLE Matches (
    match_id INT AUTO_INCREMENT PRIMARY KEY,
    tourney_id VARCHAR(255),
    match_num INT,
    winner_id INT,
    winner_seed INT,
    winner_entry VARCHAR(255),
    winner_name VARCHAR(255),
    winner_hand CHAR(1),
    winner_ht INT,
    winner_ioc CHAR(3),
    winner_age INT,
    loser_id INT,
    loser_seed INT,
    loser_entry VARCHAR(255),
    loser_name VARCHAR(255),
    loser_hand CHAR(1),
    loser_ht INT,
    loser_ioc CHAR(3),
    loser_age INT,
    score VARCHAR(255),
    best_of INT,
    round VARCHAR(255),
    minutes INT,
    w_ace INT,
    w_df INT,
    w_svpt INT,
    w_1stIn INT,
    w_1stWon INT,
    w_2ndWon INT,
    w_SvGms INT,
    w_bpSaved INT,
    w_bpFaced INT,
    l_ace INT,
    l_df INT,
    l_svpt INT,
    l_1stIn INT,
    l_1stWon INT,
    l_2ndWon INT,
    l_SvGms INT,
    l_bpSaved INT,
    l_bpFaced INT,
    winner_rank INT,
    winner_rank_points INT,
    loser_rank INT,
    loser_rank_points INT,
    matchDescription VARCHAR(255),
	CONSTRAINT fk_matches_tournaments FOREIGN KEY (tourney_id)
		REFERENCES Tournaments(tourney_id)
		ON DELETE NO ACTION ON UPDATE NO ACTION
);

-- -----------------------------------------------------
-- Table `Rankings`
-- -----------------------------------------------------
CREATE TABLE Rankings (
    ranking_id INT AUTO_INCREMENT PRIMARY KEY,
    ranking_date DATE,
    `rank` INT,
    player_id INT,
    points INT,
	CONSTRAINT fk_rankings_players FOREIGN KEY (player_id)
		REFERENCES Players(player_id)
		ON DELETE NO ACTION ON UPDATE NO ACTION
);
 
-- -----------------------------------------------------
-- Table `players_matches`
-- -----------------------------------------------------
CREATE TABLE players_matches (
    id INT AUTO_INCREMENT PRIMARY KEY,
    player_id INT,
    match_id INT,
    CONSTRAINT fk_playersmatches_players FOREIGN KEY (player_id)
		REFERENCES Players(player_id)
		ON DELETE NO ACTION ON UPDATE NO ACTION,
	CONSTRAINT fk_playersmatches_matches FOREIGN KEY (match_id)
		REFERENCES Matches(match_id)
		ON DELETE NO ACTION ON UPDATE NO ACTION
);