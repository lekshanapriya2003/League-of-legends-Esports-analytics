
-- League of Legends Esports Analytics Database

DROP DATABASE IF EXISTS LoL_Esports_Analytics;
CREATE DATABASE LoL_Esports_Analytics;
USE LoL_Esports_Analytics;

-- CORE TABLES (3NF)

-- 1. Champions (from ChampionTbl.csv)
CREATE TABLE Champions (
    ChampionId INT PRIMARY KEY,
    ChampionName VARCHAR(100)
);

-- 2. Summoner Match Table (The Bridge)
CREATE TABLE summoner_match_link (
    SummonerMatchId INT PRIMARY KEY,
    SummonerFk INT,
    MatchFk VARCHAR(50),
    ChampionFk INT
);


-- 3. PlayerMatchResults (from Match.csv)
-- Focused on individual win/loss and core combat stats.
CREATE TABLE PlayerMatchResults (
    SummonerMatchId INT PRIMARY KEY, -- Linked to SummonerMatchLink
    kills INT,
    deaths INT,
    assists INT,
    Win INT,
    Lane VARCHAR(20),
    FOREIGN KEY (SummonerMatchId) REFERENCES SummonerMatchLink(SummonerMatchId)
);

-- 4. MatchDetailedStats (from MatchStats.csv)
-- Focused on economic and efficiency metrics.
CREATE TABLE MatchDetailedStats (
    SummonerMatchId INT PRIMARY KEY,
    MinionsKilled INT,
    DmgDealt INT,
    DmgTaken INT,
    TurretDmgDealt INT,
    TotalGold INT,
    PrimaryKeyStone INT,
    FOREIGN KEY (SummonerMatchId) REFERENCES SummonerMatchLink(SummonerMatchId)
);

-- 5. TeamObjectives (from TeamMatchTbl.csv)
-- Global team-level data.
CREATE TABLE TeamObjectives (
    TeamMatchId INT PRIMARY KEY AUTO_INCREMENT,
    BlueBaronKills INT,
    BlueDragonKills INT,
    BlueTowerKills INT,
    BlueKills INT,
    RedBaronKills INT,
    RedDragonKills INT,
    RedTowerKills INT,
    RedKills INT,
    RedWin INT,
    BlueWin INT
);


-- LOAD DATA 


-- Load Champions
LOAD DATA LOCAL INFILE "D:/Esports_Dataset/ChampionTbl.csv"
INTO TABLE champions
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
IGNORE 1 ROWS;

-- Load Summoner Match Bridge
LOAD DATA LOCAL INFILE "D:/Esports_Dataset/SummonerMatch.csv"
INTO TABLE summoner_match_link
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
IGNORE 1 ROWS;

-- Load Results (Match.csv)
LOAD DATA LOCAL INFILE "D:/Esports_Dataset/Match.csv"
INTO TABLE player_results
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
IGNORE 1 ROWS
(@v1, @v2, @v3, @v4, @v5, @v6, @v7, @v8, @v9, @v10, @v11)
SET kills=@v8, deaths=@v9, assists=@v10, Win=@v7, Lane=@v6, 
    SummonerMatchId = (SELECT @row := @row + 1 FROM (SELECT @row := 0) r);

-- Load Stats (MatchStats.csv)
LOAD DATA LOCAL INFILE "D:/Esports_Dataset/MatchStats.csv"
INTO TABLE player_stats
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
IGNORE 1 ROWS
(@v1, @v2, @v3, @v4, @v5, @v6, @v7, @v8, @v9, @v10, @v11)
SET MinionsKilled=@v1, DmgDealt=@v2, DmgTaken=@v3, TurretDmgDealt=@v4, TotalGold=@v5, PrimaryKeyStone=@v11,
    SummonerMatchId = (SELECT @row_s := @row_s + 1 FROM (SELECT @row_s := 0) rs);

-- Load Team Objectives
LOAD DATA LOCAL INFILE "D:/Esports_Dataset/TeamMatchTbl.csv"
INTO TABLE team_objectives
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
IGNORE 1 ROWS;

-- POPULATE MASTER TABLES

INSERT INTO Matches (MatchID)
SELECT DISTINCT MatchID FROM staging_matches;

INSERT INTO Teams (TeamID, TeamName, Region)
SELECT DISTINCT TeamID, TeamName, Region
FROM staging_teams;

INSERT INTO Champions (ChampionID, ChampionName)
SELECT DISTINCT ChampionID, ChampionName
FROM staging_champions;

-- POPULATE MATCH PARTICIPANTS 

INSERT INTO MatchParticipants
(MatchID, TeamID, Side, Kills, TowerKills, DragonKills, BaronKills, RiftHeraldKills, Won)
SELECT
    MatchID,
    TeamID,
    Side,
    Kills,
    TowerKills,
    DragonKills,
    BaronKills,
    RiftHeraldKills,
    Won
FROM staging_team_stats;

-- POPULATE CHAMPION PICKS


INSERT INTO ChampionPicks (ParticipantID, ChampionID, PickPosition)
SELECT
    mp.ParticipantID,
    scp.ChampionID,
    scp.PickPosition
FROM staging_champion_picks scp
JOIN MatchParticipants mp
  ON scp.MatchID = mp.MatchID
 AND scp.TeamID = mp.TeamID
 AND scp.Side = mp.Side;

-- ANALYTICAL VIEWS

CREATE OR REPLACE VIEW vw_side_winrates AS
SELECT
    Side,
    COUNT(*) AS Matches,
    SUM(Won) AS Wins,
    ROUND(SUM(Won) * 100 / COUNT(*), 2) AS WinRate
FROM MatchParticipants
GROUP BY Side;

CREATE OR REPLACE VIEW vw_champion_stats AS
SELECT
    c.ChampionID,
    c.ChampionName,
    COUNT(*) AS PickCount,
    SUM(mp.Won) AS Wins,
    ROUND(SUM(mp.Won) * 100 / COUNT(*), 2) AS WinRate
FROM ChampionPicks cp
JOIN Champions c ON cp.ChampionID = c.ChampionID
JOIN MatchParticipants mp ON cp.ParticipantID = mp.ParticipantID
GROUP BY c.ChampionID, c.ChampionName;

CREATE OR REPLACE VIEW vw_match_summary AS
SELECT
    MatchID,
    SUM(Kills) AS TotalKills,
    MAX(CASE WHEN Side='Blue' THEN Won END) AS BlueWin,
    MAX(CASE WHEN Side='Red' THEN Won END) AS RedWin
FROM MatchParticipants
GROUP BY MatchID;

-- STORED PROCEDURES

DELIMITER //
CREATE PROCEDURE sp_TeamPerformance(IN p_TeamID INT)
BEGIN
    SELECT
        t.TeamName,
        COUNT(*) AS Matches,
        SUM(mp.Won) AS Wins,
        ROUND(SUM(mp.Won)*100/COUNT(*),2) AS WinRate,
        ROUND(AVG(mp.Kills),2) AS AvgKills
    FROM Teams t
    JOIN MatchParticipants mp ON t.TeamID = mp.TeamID
    WHERE t.TeamID = p_TeamID
    GROUP BY t.TeamName;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_ChampionAnalysis(IN p_ChampionID INT)
BEGIN
    SELECT
        c.ChampionName,
        COUNT(*) AS Picks,
        SUM(mp.Won) AS Wins,
        ROUND(SUM(mp.Won)*100/COUNT(*),2) AS WinRate
    FROM ChampionPicks cp
    JOIN Champions c ON cp.ChampionID = c.ChampionID
    JOIN MatchParticipants mp ON cp.ParticipantID = mp.ParticipantID
    WHERE c.ChampionID = p_ChampionID
    GROUP BY c.ChampionName;
END//
DELIMITER ;

-- SAMPLE ANALYTICS QUERIES

SELECT * FROM vw_side_winrates;

SELECT * FROM vw_champion_stats
ORDER BY WinRate DESC
LIMIT 20;

SELECT * FROM vw_match_summary
ORDER BY TotalKills DESC
LIMIT 10;
