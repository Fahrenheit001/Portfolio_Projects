-- 1. 
SELECT 
    SUM(new_cases) AS total_cases, 
    SUM(CAST(new_deaths AS INT)) AS total_deaths, 
    (CAST(SUM(CAST(new_deaths AS INT)) AS FLOAT) / NULLIF(SUM(new_cases), 0)) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;

-- Just a double check based off the data provided
-- numbers are extremely close so we will keep them - The Second includes "International"  Location


--Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
--From PortfolioProject..CovidDeaths
----Where location like '%states%'
--where location = 'World'
----Group By date
--order by 1,2


-- 2. 
-- We take these out as they are not inluded in the above queries and want to stay consistent
-- European Union is part of Europe

Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is null 
and location not in ('World', 'European Union', 'International')
Group by location
order by TotalDeathCount desc


-- 3.
SELECT 
    Location, 
    CAST(Population AS BIGINT) AS Population,
    MAX(CAST(total_cases AS BIGINT)) AS HighestInfectionCount,  
    MAX(CAST(total_cases AS FLOAT) / NULLIF(CAST(Population AS FLOAT), 0) * 100) AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE Population IS NOT NULL
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC;

-- 4.
SELECT 
    Location, 
    CAST(Population AS BIGINT) AS Population,
    Date,
    MAX(CAST(total_cases AS BIGINT)) AS HighestInfectionCount,
    MAX(CAST(total_cases AS FLOAT) / NULLIF(CAST(Population AS FLOAT), 0) * 100) AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE Population IS NOT NULL
GROUP BY Location, Population, Date
ORDER BY PercentPopulationInfected DESC;

