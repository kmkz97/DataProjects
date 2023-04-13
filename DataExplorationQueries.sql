SELECT *
FROM DataExplorationProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4


-- Exploring data that we'll be using
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1, 2


-- Looking at Total Cases vs Total Deaths
-- Likelihood of dying if you cintract Covid in my country
SELECT Location, date, total_cases, total_deaths, (total_deaths*1.0/total_cases*1.0)*100 AS DeathPercentage
FROM CovidDeaths
WHERE Location = 'Pakistan'
ORDER BY 1, 2


-- Looking at Total cases vs Population
SELECT Location, date, population, total_cases, (total_cases*1.0/population*1.0)*100 AS CovidPercentage
FROM CovidDeaths
WHERE Location = 'Pakistan'
ORDER BY 1, 2

-- Looking at countries with the highest covid infection rate
SELECT Location, population, MAX(total_cases) AS TotalCase, MAX(total_cases*1.0/population*1.0)*100 AS InfectionRate
FROM CovidDeaths
GROUP BY Location, population
ORDER BY 4 DESC

-- Let's break it down by continent
-- Looking at continents with highest death count
SELECT continent, MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

UPDATE CovidDeaths
SET new_cases = NULL
WHERE new_cases = 0

-- Global aggregates
SELECT date, SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, (SUM(new_deaths)*1.0/SUM(new_cases)*1.0)*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1


-- Looking at the Vaccinations Table
SELECT Top 5 *
FROM CovidVaccinations


-- Looking at new vaccinations

SELECT dea.continent, dea.location, dea.date, population, new_vaccinations, SUM(new_vaccinations)
FROM DataExplorationProject..CovidDeaths dea
JOIN DataExplorationProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3

-- Looking at new vaccinations and cumulative vaccinations

SELECT dea.continent, dea.location, dea.date, population, new_vaccinations, 
	SUM(CONVERT(bigint, new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS CumVac
FROM DataExplorationProject..CovidDeaths dea
JOIN DataExplorationProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3

-- Using CTE 

WITH PopvsVac (Continent, Location, Date, Population, NewVac, TotalVac)
as
(
SELECT dea.continent, dea.location, dea.date, population, new_vaccinations, 
	SUM(CONVERT(bigint, new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS CumVac
FROM DataExplorationProject..CovidDeaths dea
JOIN DataExplorationProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (TotalVac*1.0/Population*1.0)*100 AS VacPercentage
FROM PopvsVac
ORDER BY 2, 3

-- Using TEMP TABLE

DROP TABLE IF EXISTS #PopvsVac
CREATE TABLE #PopvsVac (
Continent varchar(50),
Location varchar(50),
Date Date,
Population bigint,
NewVac int,
TotalVac float
)

INSERT INTO #PopvsVac
Select dea.continent, dea.location, dea.date, population, new_vaccinations, 
	SUM(CONVERT(bigint, new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS CumVac
FROM DataExplorationProject..CovidDeaths dea
JOIN DataExplorationProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (TotalVac/Population)*100 AS VacPercentage
FROM #PopvsVac
ORDER BY 2, 3


-- Creating a view for visualization later
Create View DeathbyContinent as
SELECT continent, MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent

-- Creating a Stored Procedure to View total cases, total deaths and death percentage for individual countries

CREATE PROCEDURE CountryTotals
@loc nvarchar(100)
AS
Select location, MAX(total_cases) AS CaseTotal, MAX(total_deaths) AS DeathTotal, (MAX(total_deaths)*1.0/MAX(total_cases)*1.0)*100 AS DeathPercent
FROM DataExplorationProject..CovidDeaths
WHERE location = @loc
GROUP BY location
ORDER BY DeathPercent DESC

-- Executing the stored procedure to view totals for Pakistan

EXEC CountryTotals @loc = 'Pakistan'
