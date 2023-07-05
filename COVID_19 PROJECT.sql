SELECT * 
FROM Covid_19..CovidDeaths
ORDER BY 3, 4

--SELECT * 
--FROM Covid_19..CovidVaccination
--ORDER BY 3, 4

-- Select Data that I am going to use.
SELECT Location, date, total_cases, new_cases, total_deaths, population
From Covid_19..CovidDeaths
Where continent IS NOT NULL
order by 1,2

-- Total Cases vs Total Deaths--> (total_deaths/total_cases)*100
-- Shows likelihood of dying if you contract covid in your country

SELECT Location, date, total_cases,total_deaths, (CAST(total_deaths AS decimal)/total_cases)
FROM Covid_19..CovidDeaths
WHERE location LIKE '%states%' AND continent IS NOT NULL 
ORDER BY 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

SELECT Location, date, Population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
FROM Covid_19..CovidDeaths
--Where location like '%states%'
ORDER BY 1,2

-- Countries with Highest Infection Rate compared to Population

SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount, Max((total_cases/population))*100 AS PercentPopulationInfected
FROM Covid_19..CovidDeaths
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC


-- Countries with Highest Death Count per Population

SELECT Location, MAX(cast(Total_deaths AS int)) AS TotalDeathCount
FROM Covid_19..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY Location
ORDER BY TotalDeathCount DESC


-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population using location data
SELECT Location, MAX(cast(Total_deaths AS int)) AS TotalDeathCount
FROM Covid_19..CovidDeaths
WHERE continent IS NULL 
GROUP BY Location
ORDER BY TotalDeathCount DESC
--(The result is much more acurate)

-- Showing contintents with the highest death count per population
SELECT continent, MAX(cast(Total_deaths AS int)) AS TotalDeathCount
FROM Covid_19..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY TotalDeathCount DESC
--(The result is not looking acurate)


-- GLOBAL NUMBERS
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths as int)) AS total_deaths, SUM(CAST(new_deaths AS int))/SUM(New_Cases)*100 AS DeathPercentage
FROM Covid_19..CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 1,2

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS decimal)) OVER (Partition by dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM Covid_19..CovidDeaths AS dea
JOIN Covid_19..CovidVaccination AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
ORDER BY 2,3

-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS decimal)) OVER (Partition by dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100    # With out using CTE it is not possible to do the calculation for RollingPeopleVaccinated
FROM Covid_19..CovidDeaths AS dea
JOIN Covid_19..CovidVaccination AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
--ORDER BY 2,3
)
SELECT *, ROUND((RollingPeopleVaccinated/Population)*100,2) AS RollingPeopleVaccinatedPercentage
FROM PopvsVac


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS decimal)) OVER (Partition by dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100    # With out using CTE it is not possible to do the calculation for RollingPeopleVaccinated
FROM Covid_19..CovidDeaths AS dea
JOIN Covid_19..CovidVaccination AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL 
--ORDER BY 2,3
Select *, ROUND((RollingPeopleVaccinated/Population)*100,2) AS RollingPeopleVaccinatedPercentage
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS decimal)) OVER (Partition by dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100    # With out using CTE it is not possible to do the calculation for RollingPeopleVaccinated
FROM Covid_19..CovidDeaths AS dea
JOIN Covid_19..CovidVaccination AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
--ORDER BY 2,3


SELECT * 
FROM PercentPopulationVaccinated

