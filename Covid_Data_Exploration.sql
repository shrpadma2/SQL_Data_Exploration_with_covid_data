----------------------------------------Covid 19 Data Exploration----------------------------------------- 

--Skills used: JOINs, CTE's, Temp Tables, Windows Functions, Aggregate Functions, 
--             Creating Views, Converting Data Types 
----------------------------------------------------------------------------------------------------------

SELECT *
FROM CovidData.dbo.CovidDeaths
WHERE continent is not null
ORDER BY 3,4;

SELECT * 
FROM CovidData.dbo.CovidVaccinations
ORDER BY location,date;


--Looking at the data used in most of the cases in this project
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidData.dbo.CovidDeaths
ORDER BY location, date;



-- 1) Total Cases Vs Total Deaths 
--What is the country wise number of total cases and total deaths on each day reported?

SELECT location, date, total_cases, total_deaths, 
	ROUND((total_deaths/total_cases)* 100, 3) as DeathPercentage
FROM CovidData.dbo.CovidDeaths 
WHERE location = 'United States'	
ORDER BY date ASC;



-- 2) Total Cases Vs Population
--  What is the country wise percentage of population which contracted covid on each day reported?

SELECT location, date, total_cases, total_deaths, 
	ROUND((total_cases/population)* 100, 3) as PercentPopulationInfected
FROM CovidData.dbo.CovidDeaths 
WHERE location = 'United States'
ORDER BY date ASC;



-- 3) Which are the countries with the highest infection rate with respect to the population?

SELECT location, population, 
	MAX(total_cases) as HighestInfectionCount, 
	ROUND(CAST(MAX(total_cases/population)* 100 as FLOAT), 2) as PercentPopulationInfected
FROM CovidData.dbo.CovidDeaths 
GROUP BY location, population
ORDER BY PercentPopulationInfected ASC;



-- 4) Which are the countries with highest death count with respect to the population?

SELECT location, 
MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM CovidData.dbo.CovidDeaths 
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount ASC;



-- 5) How much is the number of total cases, number of total deaths and percentages of death across the entire world on each date?

SELECT date, 
	SUM(new_cases) as sum_new_cases, 
	SUM(CAST(new_deaths as int)) as sum_new_deaths,  
	ROUND(SUM(CAST(new_deaths as int))/SUM(new_cases)*100, 2) as DeathPercentage
FROM CovidData.dbo.CovidDeaths 
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date ASC;



-- 6) A:  Total Population Vs Vaccinations
-- How much of the total number of people in the world that have been vaccinated by that date? (Analysis using joins)

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) over (Partition BY dea.location ORDER BY dea.location, dea.date ) as rolling_people_vaccinated
FROM CovidData.dbo.CovidVaccinations AS vac
JOIN CovidData.dbo.CovidDeaths AS dea
	ON dea.location = vac.location 
AND dea.date = vac.date 
WHERE dea.continent IS NOT NULL
ORDER BY dea.continent,  dea.location ;



-- 6) B:  Total Population Vs Vaccinations
-- How much of the total number of people in the world that have been vaccinated by that date? (Analysis using common table expression (CTE))

WITH PopvsVac(Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) as
	(
		SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(convert(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
		FROM CovidData.dbo.CovidVaccinations AS vac
		JOIN CovidData.dbo.CovidDeaths AS dea
		ON dea.location = vac.location and dea.date = vac.date 
		WHERE dea.continent is not null
	)
SELECT *,
	ROUND((RollingPeopleVaccinated/Population)*100, 2) PercentPplVaccinatedOnDate
FROM PopvsVac;



-- 6) C:  Total Population Vs Vaccinations
-- How much of the total number of people in the world that have been vaccinated by that date? (Analysis using temporary tables)

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
	(
		continent NVARCHAR(255),
		location NVARCHAR(255),
		date DATETIME,
		Population NUMERIC,
		new_vaccination NUMERIC,
		RollingPeopleVaccinated	NUMERIC
	)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(convert(bigint, vac.new_vaccinations)) over (Partition BY dea.location ORDER BY dea.location, dea.date) 
	as RollingPeopleVaccinated
FROM CovidData.dbo.CovidVaccinations AS vac
JOIN CovidData.dbo.CovidDeaths AS dea
on dea.location = vac.location and dea.date = vac.date 
WHERE dea.continent is not null;

SELECT *,(RollingPeopleVaccinated/Population)*100 as PercentPplVaccinatedOnDate
FROM #PercentPopulationVaccinated;



-- 6) D:  Total Population Vs Vaccinations
-- How much of the total number of people in the world that have been vaccinated by that date? (Analysis using view)

Create View  PercentPopulationVaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(convert(bigint, vac.new_vaccinations)) over (Partition BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM CovidData.dbo.CovidVaccinations AS vac
JOIN CovidData.dbo.CovidDeaths AS dea
ON dea.location = vac.location 
	AND dea.date = vac.date 
WHERE dea.continent IS NOT NULL;


--DROP VIEW PercentPopulationVaccinated;

SELECT * FROM PercentPopulationVaccinated;
