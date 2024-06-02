-- FURTHER ANALYSIS 
-- Country Participations

CREATE VIEW country_participation AS

WITH home AS (SELECT DISTINCT Home_Team_Name AS team_name,
					 Year
			   FROM dbo.worldcup1930_2018)
			  ,

away AS (SELECT DISTINCT Away_Team_Name AS team_name,
		 Year
		 FROM dbo.worldcup1930_2018
		 ),

dataunion AS (SELECT *
			  FROM home

			 UNION ALL

			 SELECT *
			 FROM away
			 ),

participations AS (SELECT DISTINCT team_name,year
				   FROM dataunion
				   )

SELECT team_name,
	   COUNT(*) AS participation

FROM participations
GROUP BY team_name


-- World Cup Winners
WITH step1 AS (SELECT *,
CASE WHEN Home_Team_Goals > Away_Team_Goals THEN Home_Team_Name
	 WHEN Away_Team_Goals > Home_Team_Goals THEN Away_Team_Name
	 ELSE 'Draw' END AS 'Winner'
FROM WorldCupMatches
)

SELECT Winner,
COUNT(*) AS 'World_Cups_Won'
FROM step1
WHERE Stage = 'Final'
GROUP BY Winner
ORDER BY 2 DESC


-- Hosted Tournaments by Country
CREATE VIEW tournament_hosts AS

WITH step1 AS (SELECT DISTINCT Year,
					  Location
			   FROM dbo.worldcup1930_2018
			   )

SELECT Location, 
	   COUNT(*) hosted_tournaments
FROM step1 
GROUP BY Location







