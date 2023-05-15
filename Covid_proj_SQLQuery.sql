Use PortProject

--THIS IS A LITTLE EXPLORATORY PEEK INTO THE COVID DATASET; IT IS A LARGE DATASET AND MORE CAN BE DONE ON IT THAN WHAT IS SEEN BELOW

--First as it is always done, let us take an overview of the dataset we have
SELECT * FROM 
PortProject.dbo.coviddeath
ORDER BY 3, 4

--continent contains some null values, however in each of this cases the location contains continent. This is not good for our analysis
-- The code below fixes this
SELECT 
	location, 
	date, 
	total_cases, 
	new_cases, 
	total_deaths, 
	population
	FROM PortProject..coviddeath
	WHERE location is not null
	ORDER BY 1,2

--we looke at SUM death count per location, date and continent
--note that total cases and total deaths also have null characters in them, therefore you must first cast them into into INT
SELECT 
	location, 
	date, 
	continent,
	SUM(CAST(total_deaths as int)) as TotalDeathCount
	FROM PortProject..coviddeath
	WHERE continent is not null
	GROUP BY location, date, continent
	ORDER BY TotalDeathCount desc


--Now let us look at total cases against the total deaths
SELECT 
	location, 
	date, 
	population,
	CONVERT(int, max(total_cases)) as highest_rate, 
	CONVERT(int, (max(CONVERT(int, total_cases)/CONVERT(int, population))))*100 as percent_population_withcovid
	FROM PortProject..coviddeath
	WHERE continent is not null
	group by location, population, date
	ORDER BY 1,2



--first let us see how many continents we have per distribution in the data
SELECT 
	distinct continent
	FROM PortProject..coviddeath
	WHERE continent is not null
	ORDER BY 1

--time to look at the  global values in terms of new deaths per million and the accumulation of new cases
--for this we need a temporary table, we look at two methods of creating this
With tempi_tab(continent, location, date, population, new_cases, new_deaths, new_deaths_per_million, cummulative_newcases)

as
(
SELECT continent, location, date, population, new_cases, new_deaths, new_deaths_per_million,
	sum(convert(int, new_cases)) over(partition by continent order by date) as cummulative_newcases	
	FROM PortProject..coviddeath
	WHERE continent is not null and location like '%ria%'
	GROUP BY continent, location, date, population, new_cases, new_deaths, new_deaths_per_million
)

SELECT *, (cummulative_newcases/population) *100 as percentageNewCasesInPopu
FROM tempi_tab

--Another option from using CTE is to create a table 

DROP TABLE IF EXISTS PercentageNewCase -- This technique used in order to not have to always delete the created table for each code executions
CREATE TABLE PercentageNewCase(
	continent varchar(50),
	location varchar(50),
	date datetime,
	population int,
	new_cases int,
	new_deaths int,
	new_deaths_per_million int,
	cummulative_newcases int)

INSERT INTO PercentageNewCase
	SELECT
		continent, location, date, population, new_cases, new_deaths, new_deaths_per_million,
		sum(convert(int, new_cases)) over(partition by continent order by date) as cummulative_newcases	
		FROM PortProject..coviddeath
		WHERE continent is not null
		GROUP BY continent, location, date, population, new_cases, new_deaths, new_deaths_per_million
SELECT
	*, (cummulative_newcases/population) *100 as percentageNewCasesInPopu
FROM PercentageNewCase

--Taking a look at MAX total deaths per million and total death counts across all continent
--run both queries together to view both information
SELECT 
	continent,
	MAX(convert(float, isnull(total_deaths_per_million, 0))) MaxTotalDeathperMill 
	FROM PortProject..coviddeath
	WHERE continent is not null
	GROUP BY continent
	ORDER BY MaxTotalDeathperMill DESC

SELECT 
	continent, 
	MAX(CONVERT(INT, Total_deaths)) as TotalDeathCount
	FROM PortProject..coviddeath
	WHERE continent is not null
	GROUP BY continent
	ORDER BY TotalDeathCount DESC


--LET US CREATE VIEWS
CREATE VIEW 
ToTalDeathContinent as
SELECT continent, MAX(CONVERT(INT, Total_deaths)) as TotalDeathCount
FROM PortProject..coviddeath
WHERE continent is not null --and location like '%ria%'
GROUP BY continent
--ORDER BY TotalDeathCount DESC, this is invalid for views