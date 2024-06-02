-- Raw Data Wrangling

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
