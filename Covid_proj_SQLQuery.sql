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
	isnull(total_cases,0) as total_cases, 
	isnull(new_cases,0) as new_cases, 
	isnull(total_deaths,0) as total_deaths, 
	population
	FROM PortProject..coviddeath
	WHERE location is not null
	ORDER BY 1,2

--we look at SUM death count against population per location, date and continent
--note that total cases and total deaths also have null characters in them, therefore you must first cast them into into INT
SELECT 
	location, 
	date, 
	continent,population,
	SUM(CAST(total_deaths as int)) as TotalDeathCount,
	(MAX(CONVERT(int, total_deaths))/population)*100 as percent_population_death
	FROM PortProject..coviddeath
	WHERE continent is not null
	GROUP BY location, date, continent, population
	ORDER BY TotalDeathCount desc


--Now let us look at max cases against the population
SELECT 
	location, 
	date, 
	population,
	MAX(CONVERT(int, total_cases)) as highest_rate, 
	(MAX(CONVERT(int, total_cases))/population)*100 as percent_population_withcovid
	FROM PortProject..coviddeath
	WHERE continent is not null
	group by location, population, date
	ORDER BY percent_population_withcovid



--first let us see how many continents we have per distribution in the data
SELECT 
	distinct continent
	FROM PortProject..coviddeath
	WHERE continent is not null
	ORDER BY 1

--time to look at the  global values in terms of new deaths per million and the accumulation of new cases
--for this we need a temporary table, we look at two methods of creating this
--First method is using a CTE, it is a quicker method and runs faster
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
ORDER BY percentageNewCasesInPopu

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
ORDER BY percentageNewCasesInPopu

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
