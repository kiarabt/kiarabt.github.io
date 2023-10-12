/*
COVID-19 Data Exploration Project
Skills used: Aggregate Functions, Converting Data Types, Creating Views, CTE's, Joins, Temp Tables
*/

SELECT *
FROM Portfolio_Project1..covidDeaths
WHERE continent is not null
ORDER BY 3,4

--Select data that we are going to be starting with

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM Portfolio_Project1..covidDeaths
ORDER BY 1,2

-- Looking at the total cases vs total deaths
-- Shows the likelihood of death in US if COVID is contracted

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM Portfolio_Project1..covidDeaths
WHERE location like '%states%'
	AND continent is not null
ORDER BY 1,2

-- Looking at the total cases vs population
-- Shows what percentage of population contracted COVID

SELECT Location, date, population, total_cases, (total_cases/population)*100 AS CasePercentage
FROM Portfolio_Project1..covidDeaths
WHERE location like '%states%'
ORDER BY 1,2

-- Countries with Highest Infection Rate Compared to Population

SELECT Location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS percent_pop_infected
FROM Portfolio_Project1..covidDeaths
GROUP BY Location, population
ORDER BY percent_pop_infected desc

-- Countries with Highest Death Count per Population

SELECT Location, MAX(cast(total_deaths as int)) AS total_death_count
FROM Portfolio_Project1..covidDeaths
-- WHERE location like '%states%'
WHERE continent is not null
GROUP BY Location
ORDER BY total_death_count desc

-- Continents with Highest Death Count per Population

SELECT continent, MAX(cast(total_deaths as int)) as total_death_count
FROM Portfolio_Project1..covidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY total_death_count desc

-- Global Numbers (Death Percentages Across the World)

--- Deaths Across the World by Date

SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM Portfolio_Project1..covidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

-- Deaths Across the World in General
SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM Portfolio_Project1..covidDeaths
WHERE continent is not null
ORDER BY 1,2


-- Total Population vs Vaccinations
-- Shows Percentage of Population That has Recieved At Least One Covid Vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location
	ORDER BY dea.location, dea.date) as rolling_vacc_total
FROM Portfolio_Project1..covidDeaths dea
JOIN Portfolio_Project1..covidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

-- Using CTE to Perform Calculation on Partition By in Previous Query

WITH PopvsVac(Continent, Location, Date, Population, new_vaccinations, rolling_vacc_total)
AS ( SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
		SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location
		ORDER BY dea.location, dea.date) as rolling_vacc_total
     FROM Portfolio_Project1..covidDeaths dea
     JOIN Portfolio_Project1..covidVaccinations vac
	 ON dea.location = vac.location
	 AND dea.date = vac.date
     WHERE dea.continent is not null )

SELECT *, (rolling_vacc_total/Population)*100
FROM PopvsVac

-- Using Temp Table to Perform Calculation on Partition By in Previous Query

DROP TABLE if exists #percent_pop_vaccinated
CREATE TABLE #percent_pop_vaccinated
( Continent nvarchar(255),
  Location nvarchar(255),
  Date datetime,
  Population numeric,
  New_vaccinations numeric,
  rolling_vacc_total numeric )

INSERT INTO #percent_pop_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
		SUM(convert(bigint,vac.new_vaccinations)) OVER (Partition by dea.location
		ORDER BY dea.location, dea.date) as rolling_vacc_total
     FROM Portfolio_Project1..covidDeaths dea
     JOIN Portfolio_Project1..covidVaccinations vac
	 ON dea.location = vac.location
	 AND dea.date = vac.date
	 WHERE dea.continent is not null

SELECT *
FROM #percent_pop_vaccinated

-- Creating View to Store Data for Later Visualizations


CREATE VIEW percent_pop_vaccinated as 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(convert(bigint,vac.new_vaccinations)) OVER (Partition by dea.location
	ORDER BY dea.location, dea.date) as rolling_vacc_total
FROM Portfolio_Project1..covidDeaths dea
JOIN Portfolio_Project1..covidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null

