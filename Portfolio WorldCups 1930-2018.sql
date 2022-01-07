-- Create Main Table 
CREATE TABLE worldcup1930_2018  (
									Year smallint,
									Datetime datetime2(7),
									Stage nvarchar(50),
									Stadium nvarchar(50),
									City nvarchar(50),
									Home_Team_Name nvarchar(50),
									Home_Team_Goals tinyint,
									Away_Team_Goals tinyint,
									Away_Team_Name nvarchar(50),
									Referee nvarchar(50),
									Referee_nationality nvarchar(50),
									MatchID int,
									Location nvarchar (255),
									Continent nvarchar (255)
									)





-- Clean and insert data from 2 tables (1930-2014 / 2018)
WITH olddata AS (   -- 1930 - 2014 data
					SELECT Year, 
						   Datetime, 
						   Stage, 
						   Stadium, 
						   City,
						   CASE WHEN Home_Team_Name LIKE  '%Ivoire%' THEN 'Ivory Coast'
						        WHEN Home_Team_Name = 'Dutch East Indies' THEN 'Indonesia' -- differentiation of Indonesia
						 		WHEN Home_Team_Name IN ('German DR','Germany FR') THEN 'Germany' --for the purpose of the anlysis Germany will be taken as 1
						 		WHEN Home_Team_Name = 'IR Iran' THEN 'Iran'
						 		WHEN Home_Team_Name = 'Korea DPR' THEN 'North Korea' 
						 		WHEN Home_Team_Name = 'Korea Republic' THEN 'South Korea' --differentiation of the actual Koreas
						 		WHEN Home_Team_Name LIKE 'rn">%' THEN RIGHT(Home_Team_Name,LEN(Home_Team_Name)-4)
						 		ELSE Home_Team_Name END AS Home_Team_Name_New,
							Home_Team_Goals, 
							Away_Team_Goals,
						    CASE WHEN Away_Team_Name LIKE  '%Ivoire%' THEN 'Ivory Coast'
						 		 WHEN Away_Team_Name = 'Dutch East Indies' THEN 'Indonesia'
						 		 WHEN Away_Team_Name IN ('German DR','Germany FR') THEN 'Germany'
						 		 WHEN Away_Team_Name = 'IR Iran' THEN 'Iran'
						 		 WHEN Away_Team_Name = 'Korea DPR' THEN 'North Korea'
						 		 WHEN Away_Team_Name = 'Korea Republic' THEN 'South Korea'
						 		 WHEN Away_Team_Name LIKE 'rn">%' THEN RIGHT(Away_Team_Name,LEN(Away_Team_Name)-4)
						 		 ELSE Away_Team_Name END AS Away_Team_Name_New,
							Referee, 
							LEFT(RIGHT(Referee,4),3) AS referee_nat,
							MatchID

					FROM WorldCupMatches
					WHERE YEAR IS NOT NULL 
				),

newdata AS 	(   -- 2018 data
				SELECT  Year, 
						Datetime, 
						Stage, 
						Stadium, 
						City, 
						CASE WHEN Home_Team_Name = 'IR Iran' THEN 'Iran'
					 		 WHEN Home_Team_Name = 'Korea Republic' THEN 'South Korea'
					 		 ELSE Home_Team_Name END AS Home_Team_Name_New,
						Home_Team_Goals, 
						Away_Team_Goals,
						CASE WHEN Away_Team_Name = 'IR Iran' THEN 'Iran'
					 		 WHEN Away_Team_Name = 'Korea Republic' THEN 'South Korea'
					 		 ELSE Away_Team_Name END AS Away_Team_Name_New,
					 	Referee, 
						LEFT(RIGHT(Referee,4),3) AS referee_nat,
						MatchID

				FROM dbo.[2018_worldcup]
			),


dataunion AS (SELECT *
			  FROM olddata

			  UNION ALL

			  SELECT *
			  FROM newdata
			  ),


data_with_duplicates AS (SELECT d.*, 
								l.location, 
								l.continent
						 FROM dataunion d
						 LEFT JOIN dbo.locations l   --add host locations (country and continent) for every tournament year
						 ON d.Year = l.year),

find_duplicates AS (SELECT *,
					ROW_NUMBER () OVER (PARTITION BY MatchID ORDER BY MatchID) AS number_row_matchid
					FROM data_with_duplicates) --assign a row_number partition by MatchID, duplicates will be shown with the number 2

-- Insert cleanead data
INSERT INTO worldcup1930_2018 

SELECT Year, 
	   Datetime, 
	   Stage, 
	   Stadium, 
	   City, 
	   Home_Team_Name_New, 
	   Home_Team_Goals, 
	   Away_Team_Goals,
	   Away_Team_Name_New, 
	   Referee, 
	   referee_nat, 
	   MatchID, 
	   Location, 
	   Continent

FROM find_duplicates
WHERE number_row_matchid = 1   --eliminate duplicates from the table








-- CREATE VIEW FOR DASHBOARD 

CREATE VIEW dashboard_help AS

SELECT Year, 
	   Datetime, 
	   Stage, 
	   Home_Team_Name AS Team_Name, 
	   Home_Team_Goals AS goals_scored, 
	   0.5 AS row_value
FROM dbo.worldcup1930_2018

UNION ALL

SELECT Year, 
	   Datetime, 
	   Stage, 
	   Away_Team_Name AS Team_Name, 
	   Away_Team_Goals AS goals_scored, 
	   0.5 AS row_value
FROM dbo.worldcup1930_2018


--!! Germany has 231 because the goals from East Germany (5) are included.










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






