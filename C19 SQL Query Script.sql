#Show likelihood of dying from COVID-19 in a country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM covid19.deaths
WHERE continent IS NOT NULL
order by 1,2

#Calculate DeathPercentage
SELECT location, date, population, total_cases, (total_cases/population) as DeathPercentage
FROM covid19.deaths
WHERE continent IS NOT NULL
order by 1,2

#Show countries with highest death count per population
SELECT location, max(total_deaths) as TotalDeathCount
FROM covid19.deaths
WHERE continent is not null
group by location
order by TotalDeathCount desc

#Calculate and sort by PercentPopulationInfected
SELECT location, population, max(total_cases) as HighestInfectionCount, max((total_cases/population))*100 as PercentPopulationInfected
FROM covid19.deaths
WHERE continent IS NOT NULL
group by location, population
order by PercentPopulationInfected desc

#Showing countries with highest death count per population
SELECT location, max(total_deaths) as TotalDeathCount
FROM covid19.deaths
WHERE continent is not null
group by location
order by TotalDeathCount desc

#Global numbers
SELECT continent, max(total_deaths) as TotalDeathCount
FROM covid19.deaths
WHERE continent is not null
group by continent
order by TotalDeathCount desc

#Total global cases and deaths
SELECT 
sum(new_cases) as total_cases,
sum(new_deaths) as total_deaths
FROM covid19.deaths
WHERE continent is not NULL
order by 1,2

#Total population vs vaccinations
SELECT deaths.continent, deaths.location, deaths.date, deaths.population,
vacc.new_vaccinations, vacc.total_vaccinations
FROM covid19.deaths deaths
RIGHT JOIN covid19.vaccinations vacc
ON deaths.location = vacc.location
AND deaths.date = vacc.date
WHERE deaths.continent is not NULL
AND vacc.new_vaccinations is not NULL
AND vacc.total_vaccinations > 0
order by 2,3

#CTE to perform calculation on partition for total population vs vaccinations
WITH PopulationVSVaccine AS (
SELECT deaths.continent, deaths.location, deaths.date, deaths.population,
vacc.new_vaccinations, vacc.total_vaccinations
FROM covid19.deaths deaths
JOIN covid19.vaccinations vacc
ON deaths.location = vacc.location
AND deaths.date = vacc.date
WHERE deaths.continent is not NULL
AND vacc.total_vaccinations > 0
order by 2,3
)
SELECT *, (total_vaccinations/population)*100 AS PctTotalVaccinations
FROM PopulationVSVaccine

#Temp table combines data for calculation on partition by
DROP TABLE IF EXISTS
CREATE TABLE TempData (
Continent VARCHAR,
Location VARCHAR,
Date DATETIME;
Month_of_year DATETIME,
Population NUMERIC,
New_cases NUMERIC,
total_cases NUMERIC,
New_vaccinations NUMERIC,
#add new calculation for rolling total of vaccines
total_vaccinated_rolling NUMERIC
);

INSERT INTO TempData
SELECT deaths.continent, deaths.location, deaths.date, 
DATEFROMPARTS(YEAR(deaths.date), MONTH(deaths.date), 1) AS month_of_year,
deaths.population, deaths.newcase, deaths.total_cases,
vacc.new_vaccinations, vacc.total_vaccinations
SUM(vacc.new_vaccinations)
OVER (PARTITION BY 
deaths.location
order by deaths.location, deaths.date)
AS total_vaccinated_rolling

FROM covid19.deaths deaths
JOIN covid19.vaccinations vacc
ON deaths.location = vacc.location
AND deaths.date = vacc.date
WHERE deaths.continent is not null

