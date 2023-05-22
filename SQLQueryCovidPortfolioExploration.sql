SELECT location,date,total_cases,new_cases,total_deaths,population
FROM CovidDeaths$
ORDER BY 1,2

-- Looking at total cases vs total deaths

SELECT location,date,total_cases,total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidDeaths$
WHERE location like '%states%'
ORDER BY 1,2

-- Looking at total cases vs population

SELECT location,date,total_cases,population, (total_cases/population)*100 AS CovidPercentage
FROM CovidDeaths$
WHERE location like '%states%'
ORDER BY 1,2

-- Looking at countries with highest infection rate compaired to population

SELECT location,population, MAX(total_cases) AS HighestInfectonCount, MAX(total_cases/population)*100 AS PercentPopulationInfected
FROM CovidDeaths$
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC 

-- Showing countries with highest death count per population

SELECT location, MAX(cast(Total_deaths as int)) AS TotalDeathCount
FROM CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC 

-- Showing death count by continent

SELECT continent, MAX(cast(Total_deaths as int)) AS TotalDeathCount
FROM CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC 

-- Global daily numbers

SELECT date,SUM(new_cases) AS TotalCases, SUM(cast(new_deaths AS int)) AS TotalDeaths, (SUM(CAST(new_deaths AS int))/SUM(new_cases))*100 AS DeathPercentage
FROM CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2


-- Joining CovidVaccinations Table
-- Total population vs vaccinations using a CTE

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS (
SELECT d.continent, d.location , d.date, d.population, v.new_vaccinations, 
 SUM(CONVERT(int,v.new_vaccinations)) OVER 
 (PARTITION BY d.Location ORDER BY d.Location, d.date) AS RollingPeopleVaccinated
FROM CovidDeaths$ AS d
JOIN CovidVaccinations$ AS v 
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL
)

SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac
ORDER BY 2,3


-- Total Pop vs Vaccinations using temp table

DROP table if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric)

INSERT INTO #PercentPopulationVaccinated
SELECT d.continent, d.location , d.date, d.population, v.new_vaccinations, 
 SUM(CONVERT(int,v.new_vaccinations)) OVER 
 (PARTITION BY d.Location ORDER BY d.Location, d.date) AS RollingPeopleVaccinated
FROM CovidDeaths$ AS d
JOIN CovidVaccinations$ AS v 
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated
ORDER BY 2,3


-- Creating view to save data for visualizations

CREATE VIEW PercentPopulationVaccinated as
SELECT d.continent, d.location , d.date, d.population, v.new_vaccinations, 
 SUM(CONVERT(int,v.new_vaccinations)) OVER 
 (PARTITION BY d.Location ORDER BY d.Location, d.date) AS RollingPeopleVaccinated
FROM CovidDeaths$ AS d
JOIN CovidVaccinations$ AS v 
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL

