/*1. What range of years for baseball games played does the provided database cover?*/ 

SELECT MIN(year), MAX(year)
FROM homegames;


/*2. Find the name and height of the shortest player in the database. 
How many games did he play in? What is the name of the team for which he played?*/

--mine
SELECT playerid, namefirst, namelast, namegiven, height, debut, finalgame, teams.name
FROM people
	 LEFT JOIN appearances
	 USING (playerid)
	 LEFT JOIN teams
	 USING (teamid)
ORDER BY height
LIMIT 1;

--could use this subquery
WHERE height = (SELECT MIN(height)
			   FROM people)


/*3. Find all players in the database who played at Vanderbilt University. 
Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. 
Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?*/

--code for checking
SELECT SUM(salary)::int::money
FROM salaries
WHERE playerid = 'priceda01';

--Why don't I need to have the first and last name in the group by
SELECT playerid,
	   namefirst,
	   namelast,
	   SUM(salary)::int::money AS salary
FROM people
     LEFT JOIN salaries
	 USING (playerid)
WHERE playerid IN
	(SELECT DISTINCT(playerid)
	 FROM people
	 	LEFT JOIN collegeplaying
	 	USING (playerid)
	 WHERE schoolid = 'vandy')
GROUP BY playerid
ORDER BY salary DESC NULLS LAST;


/*4. Using the fielding table, group players into three groups based on their position: 
label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", 
and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.*/

SELECT CASE WHEN pos = 'OF' THEN 'Outfield'
	   WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
	   WHEN pos IN ('P', 'C') THEN 'Battery' END AS position_played,
	   SUM(po) AS putouts
FROM fielding
WHERE yearid = '2016'
GROUP BY position_played;

--code for checking
SELECT SUM(po)
FROM fielding
WHERE yearid = '2016';


/*5. Find the average number of strikeouts per game by decade since 1920. 
Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?*/

SELECT SUM(hr) AS home_runs,
	   SUM(g) AS games,
	   yearid,
	   ROUND(SUM(hr::numeric) / SUM(g::numeric),2) AS average
FROM teams
GROUP BY yearid;

SELECT SUM(g) AS games,
	   SUM(hr) AS home_runs,
	   ROUND(SUM(hr::numeric) / SUM(g::numeric),2) AS hr_per_game,
	   SUM(so) AS strike_outs,
	   ROUND(SUM(so::numeric) / SUM(g::numeric),2) AS so_per_game,
       CASE WHEN yearid BETWEEN '1871' AND '1879' THEN '1870s'
	   WHEN yearid BETWEEN '1880' AND '1889' THEN '1880s'
	   WHEN yearid BETWEEN '1890' AND '1899' THEN '1890s'
	   WHEN yearid BETWEEN '1900' AND '1909' THEN '1900s'
	   WHEN yearid BETWEEN '1910' AND '1919' THEN '1910s'
	   WHEN yearid BETWEEN '1920' AND '1929' THEN '1920s'
	   WHEN yearid BETWEEN '1930' AND '1939' THEN '1930s'
	   WHEN yearid BETWEEN '1940' AND '1949' THEN '1940s'
	   WHEN yearid BETWEEN '1950' AND '1959' THEN '1950s'
	   WHEN yearid BETWEEN '1960' AND '1969' THEN '1960s'
	   WHEN yearid BETWEEN '1970' AND '1979' THEN '1970s'
	   WHEN yearid BETWEEN '1980' AND '1989' THEN '1980s'
	   WHEN yearid BETWEEN '1990' AND '1999' THEN '1990s'
	   WHEN yearid BETWEEN '2000' AND '2009' THEN '2000s'
	   WHEN yearid BETWEEN '2010' AND '2019' THEN '2010s'
	   ELSE 'later' END AS decade
FROM teams
GROUP BY decade
ORDER BY decade;

--this works because integers cannot hold a decimal
SELECT yearid/10 *10 AS decade
FROM teams

/*6. Find the player who had the most success stealing bases in 2016, 
where __success__ is measured as the percentage of stolen base attempts which are successful. 
(A stolen base attempt results either in a stolen base or being caught stealing.) 
Consider only players who attempted _at least_ 20 stolen bases.*/

WITH cte AS (SELECT playerid,
			 	    sb,
	   		        sb + cs AS steal_attempts
			 FROM batting
			 WHERE yearid = 2016)
SELECT namefirst,
 	   namelast,
 	   sb, 
	   steal_attempts,
	   ROUND(sb::numeric / steal_attempts::numeric * 100, 2) AS percentage_stolen
FROM cte
	 INNER JOIN people
	 USING (playerid)
WHERE steal_attempts >= '20'
GROUP BY namefirst, namelast, sb, steal_attempts
ORDER BY percentage_stolen DESC;


/*7. From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? 
What is the smallest number of wins for a team that did win the world series? 
Doing this will probably result in an unusually small number of wins for a world series champion – 
determine why this is the case. Then redo your query, excluding the problem year. 
How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? 
What percentage of the time?*/

--most wins who won
SELECT yearid,
	   teamid,
	   MAX(g) AS games_played,
	   MAX(w) AS games_won,
	   wswin
FROM teams
WHERE wswin = 'N' AND yearid >= '1970'
GROUP BY yearid, teamid, wswin
ORDER BY games_won DESC;

--least wins who won
SELECT yearid,
	   teamid,
	   MAX(g) AS games_played,
	   MAX(w) AS games_won,
	   wswin
FROM teams
WHERE wswin = 'Y' AND yearid >= '1970'
GROUP BY yearid, teamid, wswin
ORDER BY games_won;

WITH cte AS (SELECT yearid,
			 		MAX(teamid) AS team,
			 	    MAX(g) AS games_played,
	   				MAX(w) AS most_games_won,
	   				wswin
			 FROM teams
			 WHERE yearid >= '1970' AND g > 120 AND wswin = 'Y'
			 GROUP BY yearid, wswin
			 ORDER BY yearid)
SELECT COUNT(cte.yearid) AS highest_wins_also_won,
	   COUNT(teams.wswin) AS num_of_wswins,
	   ROUND((COUNT(cte.yearid)::numeric / COUNT(teams.wswin)::numeric)*100,2) AS percentage_of_years
FROM cte
	 LEFT JOIN teams
	 USING (yearid)
WHERE teams.yearid >= 1970 AND teams.wswin = 'Y' AND g > 120;

--with cte?
WITH cte3 AS(WITH cte1 AS (SELECT yearid, name, w AS wins, WSWIN FROM teams
						   WHERE (yearid BETWEEN 1970 AND 2016) AND (WSWIN = 'Y') AND (g > 120)
						   ORDER BY yearid),

				  cte2 AS (SELECT yearid, MAX(w) AS highest_w_count_that_season FROM teams
						   WHERE (yearid BETWEEN 1970 AND 2016) AND (g > 120)
						   GROUP BY yearid
						   ORDER BY yearid)
			 SELECT cte1.yearid, name, wins,highest_w_count_that_season, wswin, 
			 CASE WHEN wins >=highest_w_count_that_season THEN 1 WHEN wins < highest_w_count_that_season THEN 0 END AS WS_and_highest_wincount
			 FROM cte1
			 INNER JOIN cte2 USING(yearid))		 
SELECT COUNT(wswin) AS total_wswins, SUM(WS_and_highest_wincount) AS total_WS_and_highest_wincount, 
ROUND(((SUM(WS_and_highest_wincount)::numeric)/(COUNT(wswin)::numeric))*100,2) AS Percent_that_highest_w_wins_ws
FROM cte3;


/*8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance 
per game in 2016 (where average attendance is defined as total attendance divided by number of games). 
Only consider parks where there were at least 10 games played. 
Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.*/

SELECT hg.team, hg.park, (SUM(hg.attendance) / hg.games) AS avg_attendance
FROM homegames AS hg
WHERE year = 2016 
AND park IN(
       SELECT DISTINCT(park)
       FROM homegames AS hg
       WHERE year = 2016 AND games >= 10)
GROUP BY hg.team, hg.park, hg.games
--HAVING COUNT(*) >= 10
ORDER BY avg_attendance DESC
LIMIT 5;

--lowest 5 average attendance
SELECT hg.team, hg.park, (SUM(hg.attendance) / hg.games) AS avg_attendance
FROM homegames AS hg
WHERE year = 2016 
AND park IN(
       SELECT DISTINCT(park)
       FROM homegames AS hg
       WHERE year = 2016 AND games >= 10)
GROUP BY hg.team, hg.park, hg.games
--HAVING COUNT(*) >= 10
ORDER BY avg_attendance ASC
LIMIT 5;


/*9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? 
Give their full name and the teams that they were managing when they won the award.*/
WITH cte AS		(SELECT namefirst, namelast,playerid
				--MIN(awardsmanagers.lgid) AS al_winner, MAX(awardsmanagers.lgid)AS NL_winner
				FROM awardsmanagers
				INNER JOIN people USING(playerid)
				WHERE awardid ILIKE '%TSN%' 
				GROUP BY playerid,namefirst, namelast
				HAVING (MIN(awardsmanagers.lgid) = 'AL' AND MAX(awardsmanagers.lgid) = 'NL'))
SELECT playerid,namefirst,namelast,name,yearid,awardsmanagers.lgid AS league_award FROM cte
INNER JOIN awardsmanagers USING(playerid)
INNER JOIN managers USING(yearid,playerid)
INNER JOIN teams USING(yearid,teamid)
WHERE awardid ILIKE '%TSN%'


/*10. Find all players who hit their career highest number of home runs in 2016. 
Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. 
Report the players' first and last names and the number of home runs they hit in 2016.*/
SELECT COUNT(DISTINCT playerid)
FROM batting;

SELECT *
FROM batting;

--players and their hightest home runs
SELECT playerid,
	   MAX(hr) AS max_home_runs
FROM batting
GROUP BY playerid

SELECT playerid,
	   yearid,
	   hr
FROM batting
GROUP BY playerid, yearid, hr
ORDER BY playerid, yearid

--from aaron
WITH cte AS (SELECT playerid, MIN(yearid) AS min_year, MAX(yearid) AS max_year, MAX(hr) AS max_hr FROM batting
			 GROUP BY playerid
			 HAVING (MAX(yearid) - MIN(yearid) >=10))
SELECT playerid, namefirst, namelast, hr AS homeruns_in_2016 FROM batting
RIGHT JOIN cte USING(playerid)
INNER JOIN people USING(playerid)
WHERE yearid = 2016 AND hr = max_hr AND hr >=1;

--from liam
WITH cte AS(SELECT namefirst, 
				   namelast, 
 				   CASE WHEN MAX(hr) >= 1 AND yearid = 2016 THEN 'Y' 
				   	    ELSE 'N' END AS career_high,
 				   MAX(batting.hr) AS highest_hr, 
				   COUNT(yearid) AS years_played
			FROM people
			INNER JOIN batting 
			USING(playerid)
			GROUP BY namefirst, namelast, yearid
			ORDER BY years_played DESC)
SELECT namefirst, 
	   namelast, 
	   MAX(career_high), 
	   MAX(highest_hr) AS homeruns, 
	   years_played
FROM cte
WHERE career_high = 'Y'
GROUP BY namefirst, namelast, years_played
ORDER BY homeruns DESC

--from sree
SELECT p.playerid, 
	   p.namefirst AS firstname, 
	   p.namelast AS lastname,
       MAX(b.hr) AS max_homeruns
FROM people AS p
INNER JOIN appearances AS a 
ON p.playerid = a.playerid
INNER JOIN batting AS b 
ON p.playerid = b.playerid
INNER JOIN teams AS t 
ON a.teamid = t.teamid
WHERE
    a.yearid >= 2007 
    AND a.yearid <= 2016 
    AND b.yearid = 2016
GROUP BY p.playerid, p.namefirst, p.namelast
HAVING MAX(b.hr) = (SELECT MAX(hr)
        		    FROM batting AS b2
        			WHERE b2.playerid = p.playerid);
	
/*11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. 
As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.*/

SELECT s.teamid,
	   s.yearid,
	   t.w,
	   SUM(salary::integer::money)
FROM salaries AS s
FULL JOIN teams AS t
USING (teamid, yearid)
WHERE s.yearid >= 2000
GROUP BY s.teamid, s.yearid, t.w
ORDER BY s.teamid, s.yearid

--from sree
WITH TeamSalaries AS (SELECT teamid, yearid, SUM(salary::integer::money) AS team_salary
 					  FROM salaries
					  WHERE yearid >= 2000
					  GROUP BY teamid, yearid)
SELECT t.teamid, t.yearid, SUM(t.w) AS team_wins, ts.team_salary
FROM teams AS t
INNER JOIN TeamSalaries AS ts
ON t.teamid = ts.teamid AND t.yearid = ts.yearid
WHERE t.yearid >= 2000
GROUP BY  t.teamid, t.yearid, ts.team_salary
ORDER BY t.teamid, t.yearid;


WITH cte AS		(SELECT s.teamid, s.yearid, t.w AS wins, SUM(salary::integer::money) AS salary
				FROM salaries AS s
				FULL JOIN teams AS t USING(teamid, yearid) 
				WHERE s.yearid >= 2000
				GROUP BY s.teamid, s.yearid, t.w
				ORDER BY s.teamid, s.yearid)
SELECT teamid, yearid, wins, salary, CORR(wins::numeric,salary::numeric) OVER(PARTITION BY teamid ORDER BY yearid) AS correlation_coefficient
FROM cte

