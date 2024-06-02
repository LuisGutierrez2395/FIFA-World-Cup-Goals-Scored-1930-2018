/* Create view for dashboard
!! Germany has 231 because the goals from East Germany (5) are included.*/

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
