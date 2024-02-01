SELECT *
	FROM PortofolioProject..CovidDeaths
	WHERE continent IS NOT NULL
	ORDER BY 3, 4


----SELECT *
----	FROM PortofolioProject..CovidVaccinations
----	ORDER BY 3, 4

--select Data that we are going to be using

SELECT Location, date, total_cases, new_cases, total_deaths, population
	FROM PortofolioProject..CovidDeaths
	ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS DeathPercentage
	FROM PortofolioProject..CovidDeaths
	WHERE Location LIKE '%states%'
	ORDER BY 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid

SELECT Location, date, total_cases, population, ROUND((total_cases/population) * 100, 5) AS CasesPercentage
	FROM PortofolioProject..CovidDeaths
	WHERE Location LIKE '%states%'
	ORDER BY 1,2

-- Looking at Countries with Highest Infection Rate compared to Population

SELECT Location,  population, MAX(total_cases) as Max_case, ROUND(MAX((total_cases/population) * 100), 5) AS PercentagePopulationInfected
	FROM PortofolioProject..CovidDeaths
	--WHERE Location LIKE '%states%'
	GROUP BY Location,  population
	ORDER BY PercentagePopulationInfected DESC
	
-- Showing Countries with Highest Death Count per Population
SELECT Location,  Max(CAST(Total_deaths AS INT)) AS TotalDeathCount
	FROM PortofolioProject..CovidDeaths
	--WHERE Location LIKE '%states%'
	WHERE continent IS NOT NULL
	GROUP BY Location
	ORDER BY TotalDeathCount DESC


-- LET'S BREAK THINGS DOWN BY CONTINENT

SELECT continent,  Max(CAST(Total_deaths AS INT)) AS TotalDeathCount
	FROM PortofolioProject..CovidDeaths
	--WHERE Location LIKE '%states%'
	WHERE continent IS not NULL
	GROUP BY continent
	ORDER BY TotalDeathCount DESC

-- Showing continents with the highest death count per population

SELECT location,  Max(CAST(Total_deaths AS INT)) AS TotalDeathCount
	FROM PortofolioProject..CovidDeaths
	--WHERE Location LIKE '%states%'
	WHERE continent IS NULL
	GROUP BY location
	ORDER BY TotalDeathCount DESC


-- GLOBAL NUMBERS
SELECT date, SUM(new_cases) AS Total_cases, SUM(CAST(new_deaths AS INT)) AS Total_deaths, (SUM(CAST(new_deaths AS INT)) / SUM(new_cases)) * 100  AS DeathPercentage
	FROM PortofolioProject..CovidDeaths
	--WHERE Location LIKE '%states%'
	WHERE continent IS NOT NULL
	GROUP BY date
	ORDER BY 1,2

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.Location ORDER BY dea.Location, dea.Date)
	FROM PortofolioProject..CovidVaccinations vac
	JOIN PortofolioProject..CovidDeaths dea
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	ORDER BY 2,3

-- USE CTE
WITH PopvsVac(Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.Location ORDER BY dea.Location, dea.Date) AS RollingPeopleVaccinated
	FROM PortofolioProject..CovidVaccinations vac
	JOIN PortofolioProject..CovidDeaths dea
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated / Population) * 100
	FROM PopvsVac

-- TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated

CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)


INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.Location ORDER BY dea.Location, dea.Date) AS RollingPeopleVaccinated
	FROM PortofolioProject..CovidVaccinations vac
	JOIN PortofolioProject..CovidDeaths dea
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated / Population) * 100
	FROM #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.Location ORDER BY dea.Location, dea.Date) AS RollingPeopleVaccinated
	FROM PortofolioProject..CovidVaccinations vac
	JOIN PortofolioProject..CovidDeaths dea
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	--ORDER BY 2,3