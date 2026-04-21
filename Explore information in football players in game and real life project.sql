USE Football_player_price_analyze;
GO

--Checking the price of Man chester United price in market vs in FIFA in all VER normal Controlled

SELECT
	Name,
	price_in_market,
	price_in_FIFA,
	POS,
    goals
FROM dbo.process_data
WHERE team='Manchester United'

--Calculating VFM all of attacking players in popularity order and perfomance per match (90 minutes)


SELECT
    Name,
    VER,
    POS,
    ROUND(CASE
        WHEN POS LIKE '%ST%' OR POS LIKE '%CF%' OR POS like '%LW%' or POS like '%RW%' THEN
            CASE 
                WHEN price_in_FIFA <> 0
                    THEN (goals + assists * 0.8) / price_in_FIFA
                ELSE 0
            END

        WHEN POS LIKE '%CM%' OR POS LIKE '%CAM%' 
          OR POS LIKE '%LM%' OR POS LIKE '%RM%' THEN
            CASE 
                WHEN price_in_FIFA <> 0
                    THEN (goals * 0.8 + assists) / price_in_FIFA
                ELSE 0
            END
        WHEN POS LIKE '%CB%' OR POS LIKE '%RB%' OR POS LIKE '%LB%' OR POS LIKE '%LWB%' OR POS LIKE '%RWB%' OR POS LIKE '%GK%'
        THEN -1
    END,5) AS VFM_for_attacking_player,

    ROUND(
    CASE 
        WHEN minutes_played <>0 THEN
            assists/minutes_played * 90
        ELSE
            -1
    END
    ,5) AS assists_per_90,

    ROUND(
    CASE 
        WHEN minutes_played <>0 THEN
            goals/minutes_played * 90
        ELSE
            -1
    END
    ,5) AS goals_per_90,
    price_in_FIFA,
    max_price_in_market,
    Popularity
FROM dbo.process_data
ORDER BY Popularity desc

--VFM for attacking player average across teams and taking top team has higest VFM for attacking players in VER Normal Controlled

SELECT
    team,
    ROUND(AVG(CASE
        WHEN POS LIKE '%ST%' OR POS LIKE '%CF%' OR POS LIKE '%LW%' OR POS LIKE '%RW%' THEN
            CASE WHEN price_in_FIFA > 0 THEN (goals + assists * 0.8) / price_in_FIFA END
        WHEN POS LIKE '%CM%' OR POS LIKE '%CAM%' OR POS LIKE '%LM%' OR POS LIKE '%RM%' THEN
            CASE WHEN price_in_FIFA > 0 THEN (goals * 0.8 + assists) / price_in_FIFA END
        ELSE NULL 
    END), 5) AS Average_VFM_Attacking_Team
FROM dbo.process_data
WHERE VER = 'Normal Controlled'
GROUP BY team 
ORDER BY Average_VFM_Attacking_Team DESC;

--Top goals team (fix the goals in integer)  and top goals per 90 in VER Normal Controlled

SELECT
    team,
   	Round(SUM(goals),1)*10 as total_score,
    ROUND(
        CASE 
            WHEN SUM(minutes_played) <>0 THEN
                SUM (assists)/ SUM(minutes_played) * 90
        ELSE
            -1
    END
    ,5) AS Average_assists_per_90,

    ROUND(
        CASE 
            WHEN SUM(minutes_played) <>0 THEN
                SUM (goals)/SUM(minutes_played) * 90
        ELSE
            -1
    END
    ,5) AS Average_goals_per_90
FROM dbo.process_data
WHERE VER='Normal Controlled'
GROUP BY team
ORDER BY total_score desc

--Which player has highest perfomance in scoring across nations
SELECT
    b.nationality,
    a.Name,
    SUM(a.goals) AS total_goals,
    ROUND(
        CASE 
            WHEN SUM(a.minutes_played) > 0 THEN
                (SUM(a.assists * 1.0) / SUM(a.minutes_played)) * 90
            ELSE NULL
        END, 5
    ) AS avg_assists_per_90,
    ROUND(
        CASE 
            WHEN SUM(a.minutes_played) > 0 THEN
                (SUM(a.goals * 1.0) / SUM(a.minutes_played)) * 90
            ELSE NULL
        END, 5
    ) AS avg_goals_per_90
FROM dbo.process_data AS a
LEFT JOIN dbo.process_data AS b 
    ON a.Name LIKE '%' + b.name + '%' 
    OR b.name LIKE '%' + a.Name + '%'
WHERE VER = 'Normal Controlled'
	AND b.nationality IS NOT NULL 
GROUP BY b.nationality, a.Name
ORDER BY avg_goals_per_90 DESC;

---Overall football inforamation we got

SELECT
    COUNT(DISTINCT b.team) AS Total_teams,
    COUNT(DISTINCT a.nationality) AS Total_nations,
    COUNT(b.Name) AS Total_players
FROM dbo.fifa_players AS a
LEFT JOIN dbo.process_data AS b 
    ON a.Name LIKE '%' + b.name + '%' 
    OR b.name LIKE '%' + a.Name + '%'
