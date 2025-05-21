-- View all records from the CovidDeaths table
-- Ordered by column 3 (date) and column 4 (population)
Select*
From PortfolioProject..[CovidDeaths]
order by 3,4

-- View all records from the CovidVaccinations table
-- Ordered by column 3 (date) and column 4 (population)
Select*
From PortfolioProject..[CovidVaccinations]
order by 3,4

-- Select specific columns from the CovidDeaths table:
-- location (country/region), date, total cases, new cases, total deaths, and population
-- Ordered by location first, then by date
Select location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..[CovidDeaths]
Order by 1,2

-- Looking at the Total Cases vs. Total Deaths.
-- CAST(total_deaths AS FLOAT): Ensures the division is done in floating-point, giving you decimal results.
-- NULLIF(total_cases, 0): Prevents division by zero by returning NULL if total_cases is 0.
Select location, date, total_cases, total_deaths, CAST(total_deaths AS FLOAT) / NULLIF(total_cases, 0) * 100 AS DeathPercentage
From PortfolioProject..[CovidDeaths]
Order by 1,2

-- Displays the liklihood of dying within the USA if you contracted covid.
Select location, date, total_cases, total_deaths, CAST(total_deaths AS FLOAT) / NULLIF(total_cases, 0) * 100 AS DeathPercentage
From PortfolioProject..[CovidDeaths]
Where location like '%states%'
Order by 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid
Select location, date, total_cases, population, CAST(total_cases AS FLOAT) / NULLIF(population, 0) * 100 AS InfectionPercentage
From PortfolioProject..[CovidDeaths]
Where location like '%states%'
Order by 1,2

-- MAX(total_cases): Finds the highest case count ever recorded for each country.
-- GROUP BY location: Groups the results by country.
-- ORDER BY HighestTotalCases DESC: Sorts countries from highest to lowest total case count.
-- WHERE continent IS NOT NULL: Ensures you're comparing actual countries and not aggregate regions like "World" or "Europe".
-- 'N0' = number format with 0 decimal places and commas as thousands separators.
SELECT 
    location,
    FORMAT(MAX(total_cases), 'N0') AS HighestTotalCases
FROM 
    PortfolioProject..[CovidDeaths]
WHERE 
    continent IS NOT NULL  -- Optional: filters out regions like 'World' or continents
GROUP BY 
    location
ORDER BY 
    HighestTotalCases DESC;


-- CountryMaxCases: Gets the max total_cases per country.
-- MaxCasesWithYear: Finds all rows matching that max (joining back to full data), then uses ROW_NUMBER() to rank them.
-- The final SELECT pulls just the first match per country using WHERE rn = 1.
WITH CountryMaxCases AS (
    SELECT 
        location,
        MAX(total_cases) AS MaxCases
    FROM 
        PortfolioProject..[CovidDeaths]
    WHERE 
        continent IS NOT NULL
        AND YEAR(date) BETWEEN 2020 AND 2022
    GROUP BY 
        location
),

MaxCasesWithYear AS (
    SELECT 
        cd.location,
        YEAR(cd.date) AS Year,
        cd.total_cases,
        ROW_NUMBER() OVER (PARTITION BY cd.location ORDER BY cd.date) AS rn
    FROM 
        PortfolioProject..[CovidDeaths] cd
    JOIN 
        CountryMaxCases cm
        ON cd.location = cm.location AND cd.total_cases = cm.MaxCases
    WHERE 
        continent IS NOT NULL
        AND YEAR(cd.date) BETWEEN 2020 AND 2022
)
-- This query is showing the location (country or region) 
-- and the year when that location had its highest number of total COVID cases
SELECT 
    location,
    Year,
    FORMAT(total_cases, 'N0') AS HighestTotalCases
FROM 
    MaxCasesWithYear
WHERE 
    rn = 1
ORDER BY 
    total_cases DESC;

-- This query below finds the highest number of reported COVID-19 cases (total_cases) 
-- and the highest percentage of the population infected for each location.
-- 1. CAST is used to convert 'total_cases' and 'Population' from text (varchar) 
--    into numeric types (BIGINT or FLOAT) so we can do calculations safely.
-- 2. NULLIF(Population, 0) avoids dividing by zero (which would cause an error).
-- 3. ISNUMERIC() ensures only rows with valid numeric values in 'total_cases' 
--    and 'Population' are used in the calculation.
-- 4. MAX is used to get the highest case count and the highest infection percentage 
--    for each location across all dates in the dataset.
-- 5. GROUP BY Location and Population so that we calculate one result per country/location.
-- 6. ORDER BY Location and Population to sort the results alphabetically.
 
 SELECT 
    Location, 
    MAX(CAST(total_cases AS BIGINT)) AS HighestInfectionCount,
    MAX((CAST(total_cases AS FLOAT) / NULLIF(CAST(Population AS FLOAT), 0)) * 100) AS PercentPopulationInfected
FROM PortfolioProject..[CovidDeaths]
WHERE 
    ISNUMERIC(Population) = 1 
    AND ISNUMERIC(total_cases) = 1
GROUP BY 
    Location, 
    Population
ORDER BY 
    Location, Population;  

-- This will show countries with the Highest death count per population.
-- This query retrieves the highest reported death count for each country, formatted with commas for readability.
-- 1. SELECT Location, TotalDeathCount: We select the country (Location) and the total death count (TotalDeathCount) for each country.
-- 2. CAST(Total_deaths AS BIGINT): We convert the "Total_deaths" column into a numeric type (BIGINT) to ensure correct calculations, as it may be stored as text.
-- 3. MAX(...): Since there are multiple records per country, we use MAX to find the highest death count recorded for each country.
-- 4. FORMAT(..., 'N0'): This formats the death count with commas for easier reading (e.g., 1234567 becomes 1,234,567).
-- 5. WHERE ISNUMERIC(Total_deaths) = 1: This ensures we only include rows where "Total_deaths" is a valid number, ignoring any non-numeric values.
-- 6. GROUP BY Location: We group the data by country (Location) to get one result per country.
-- 7. ORDER BY Location ASC: Finally, we sort the results alphabetically by country name so the list is in alphabetical order.
SELECT 
    Location, 
    FORMAT(MAX(CAST(Total_deaths AS BIGINT)), 'N0') AS TotalDeathCount
FROM PortfolioProject..[CovidDeaths]
WHERE ISNUMERIC(Total_deaths) = 1
GROUP BY Location
ORDER BY Location ASC


-- Provides the Total Death Count for every Continent.
SELECT 
    COALESCE(Continent, 'World') AS Continent, 
    FORMAT(MAX(CAST(Total_deaths AS BIGINT)), 'N0') AS TotalDeathCount
FROM PortfolioProject..[CovidDeaths]
WHERE Continent IS NULL OR Continent IS NOT NULL
GROUP BY COALESCE(Continent, 'World')
ORDER BY 
    CASE 
        WHEN COALESCE(Continent, 'World') = 'World' THEN 0 
        ELSE 1 
    END, 
    Continent ASC;

-- Global Numbers
-- CAST(new_deaths AS FLOAT): Ensures decimal division.
-- NULLIF(SUM(new_cases), 0): Prevents division by zero.
-- Renamed columns (optional but clearer): TotalCases, TotalDeaths.
Select date, 
    SUM(new_cases) AS TotalCases, 
    SUM(new_deaths) AS TotalDeaths,
    (SUM(CAST(new_deaths AS FLOAT)) / NULLIF(SUM(new_cases), 0)) * 100 AS DeathPercentage
FROM PortfolioProject..[CovidDeaths]
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

-- Total Cases, Total Deaths, Death Percentage for 2020 - 2021.
SELECT 
    SUM(new_cases) AS TotalCases, 
    SUM(new_deaths) AS TotalDeaths,
    (SUM(CAST(new_deaths AS FLOAT)) / NULLIF(SUM(new_cases), 0)) * 100 AS DeathPercentage
FROM PortfolioProject..[CovidDeaths]
WHERE continent IS NOT NULL;

-- Joining the Death and Vaccinations DBs together on Data and location.
Select *
From PortfolioProject..[CovidDeaths] dea
Join PortfolioProject..[CovidVaccinations] vac
 On dea.location = vac.location
 and dea.date = vac.date

 -- Looking at Population vs Vaccinations.
 -- Definig the Medium age.
 -- Joining the Death, Vaccinations, and Patient DBs.
SELECT  
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    CAST(pat.median_age AS INT) as median_age
FROM PortfolioProject..[CovidDeaths] dea
JOIN PortfolioProject..[CovidVaccinations] vac
    ON dea.location = vac.location
    AND dea.date = vac.date
JOIN PortfolioProject..[CovidPatients] pat
    ON dea.location = pat.location
    AND dea.date = pat.date
    where dea.continent is not NULL 
    AND vac.new_vaccinations IS NOT NULL
ORDER BY 1, 2, 3;

-- Adding a column to add up the 
-- Using Convert instead of CAST
SELECT  
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(Convert (int, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.Location, dea.date) as AccruingPeopleVaccinated,
    CAST(pat.median_age AS INT) as median_age
FROM PortfolioProject..[CovidDeaths] dea
JOIN PortfolioProject..[CovidVaccinations] vac
    ON dea.location = vac.location
    AND dea.date = vac.date
JOIN PortfolioProject..[CovidPatients] pat
    ON dea.location = pat.location
    AND dea.date = pat.date
    where dea.continent is not NULL 
    AND vac.new_vaccinations IS NOT NULL
    AND vac.new_vaccinations <> 0
ORDER BY 1, 2, 3;


-- Using a CTE.
-- Create a temporary "virtual table" called PopvsVACC
WITH PopvsVACC (
    Continent, 
    Location, 
    Date, 
    Population, 
    New_Vaccinations, 
    AccruingPeopleVaccinated, -- Running total of vaccinations per location
    Median_Age
) AS
(
    -- Select and calculate the data we need
    SELECT  
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,

        -- Calculate running total of new vaccinations for each location
        SUM(CONVERT(INT, vac.new_vaccinations)) 
            OVER (
                PARTITION BY dea.location  -- Restart the count for each country
                ORDER BY dea.location, dea.date  -- Count in date order
            ) AS AccruingPeopleVaccinated,

        -- Round median age to a whole number
        CAST(pat.median_age AS INT) AS Median_Age
    FROM PortfolioProject..[CovidDeaths] dea

    -- Join vaccination data to death data by location and date
    JOIN PortfolioProject..[CovidVaccinations] vac
        ON dea.location = vac.location
        AND dea.date = vac.date

    -- Join patient data to death data by location and date
    JOIN PortfolioProject..[CovidPatients] pat
        ON dea.location = pat.location
        AND dea.date = pat.date

    -- Only include rows where:
    -- - the continent is known (not NULL)
    -- - there is a vaccination number
    -- - the number is not zero
    WHERE dea.continent IS NOT NULL 
      AND vac.new_vaccinations IS NOT NULL
      AND vac.new_vaccinations <> 0
      AND pat.median_age IS NOT NULL
)

-- Now, use the data from the CTE we just created
SELECT *, (CAST(AccruingPeopleVaccinated AS FLOAT)) / NULLIF(Population, 0) * 100 AS PopulationVaccinated
FROM PopvsVACC
ORDER BY Location, Date;

-- Creating View to store data for later Visualizations.
-- Create a view that tracks COVID-19 vaccination progress by location and date.
-- Includes total population, new vaccinations per day, running total of vaccinations,
-- and median age of the population.
-- Filters out rows with missing continent, null vaccinations, or zero vaccinations.
Create View Population_Vaccinated as
SELECT  
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(Convert (int, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.Location, dea.date) as AccruingPeopleVaccinated,
    CAST(pat.median_age AS INT) as median_age
FROM PortfolioProject..[CovidDeaths] dea
JOIN PortfolioProject..[CovidVaccinations] vac
    ON dea.location = vac.location
    AND dea.date = vac.date
JOIN PortfolioProject..[CovidPatients] pat
    ON dea.location = pat.location
    AND dea.date = pat.date
    where dea.continent is not NULL 
    AND vac.new_vaccinations IS NOT NULL
    AND vac.new_vaccinations <> 0
--ORDER BY 1, 2, 3;

--END OF LINE.
