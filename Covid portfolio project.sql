Select *
From PortfolioProject . .CovidDeaths$
Where continent is not null
order by 3, 4

--Select *
--From PortfolioProject . .CovidVaccinations$
--Order by 3,4 

--Select the Data that is going to be used 
Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject . .CovidDeaths$
order by 1, 2 -- this is making reference to the ones from select, not from master table
			  -- this is giving it to me, over two years, but each day on both years, so 1/1/21, 1/1/22. 2/1/21, 2/1/22 need to figure out how to avoid this.
--check data types
SELECT DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE 
     TABLE_SCHEMA = 'dbo' AND
     TABLE_NAME   = 'CovidDeaths$' AND 
     COLUMN_NAME  = 'date'

-- convert date to a date format

-- Looking at Total cases vs Total deaths
--likelyhood of death if you contract covid by country and date
Select Location, dates, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject . .CovidDeaths$
Where Location = 'United Kingdom'
ORDER BY 1, 2

-- total cases vs population
-- shows what percentage of the population got covid
Select Location, dates, population, total_cases, ((total_cases/population)*100) as PercentInfected 
From PortfolioProject . .CovidDeaths$
Where Location = 'United Kingdom'
ORDER BY 1, 2

-- Countries with highest infection rate compared to population
Select Location,population, MAX(total_cases) as HighestInfectionCount, ((MAX(total_cases)/population)*100) as PercPopInfected 
From PortfolioProject . .CovidDeaths$
-- WHERE population >= 100000000
Group by Location,population
ORDER BY 4 desc

--countries with highest death count per population
Select Location,population, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject . .CovidDeaths$
Group by Location,population
ORDER BY 3 desc

Select Location,population, MAX(cast(total_deaths as int)) as HighestDeathCount, ((MAX(total_deaths)/population)*100) as PercPopDead 
From PortfolioProject . .CovidDeaths$
-- WHERE population >= 100000000
where continent is not null
Group by Location,population
ORDER BY 4 desc

-- by continent
Select continent, MAX(cast(total_deaths as int)) as HighestDeathCount
From PortfolioProject . .CovidDeaths$
where continent is not null
Group by continent
ORDER BY HighestDeathCount desc

-- view continent data to assess why death stats are so low for north america 
select continent, location 
From PortfolioProject . .CovidDeaths$
where continent is not null
Group by continent, location
order by continent;
--clearly more than jus tamerica in the continent

--total deaths for each country in north america
select continent,location, MAX(cast(total_deaths as int)) as totaldeaths
From PortfolioProject . .CovidDeaths$
where continent is not null
AND continent = 'North America'
HAVING( MAX(cast(total_deaths as int)) is not null)
Group by continent, location
order by totaldeaths desc;

select continent, location, MAX(cast(total_deaths as int)) as totaldeaths
From PortfolioProject . .CovidDeaths$
where continent is not null
AND MAX(cast(total_deaths as int)) is not null
group by continent, location
order by MAX(cast(total_deaths as int)) desc


select continent, SUM(cast(total_deaths as int)) as maxdeath
from (
    select continent, MAX(cast(total_deaths as int))
         , row_number() over (partition by continent
                              order by continent desc) as rn
    From PortfolioProject . .CovidDeaths$
) as T
group by continent;


--unable to get it to correctly format the data, will move on 

--total deaths by continent - correct
select location, MAX(cast(total_deaths as int)) as totaldeaths
From PortfolioProject . .CovidDeaths$
where continent is null
Group by location
order by totaldeaths desc

--total deaths by continent - incorrect -- only taking the max for each continent
select continent, MAX(cast(total_deaths as int)) as totaldeaths
From PortfolioProject . .CovidDeaths$
where continent is not null
Group by continent
order by totaldeaths desc

-- Global numbers by day
select dates,SUM(new_cases) as NewCases, sum(cast(new_deaths as int)) as NewDeaths, (SUM(cast(new_deaths as int))/sum(new_cases))*100 as PercentOfNewCasesThatDied
FROM PortfolioProject . .CovidDeaths$
where continent is not null 
group by dates
order by 1,2 

-- Global numbers to date
select SUM(new_cases) as NewCases, sum(cast(new_deaths as int)) as NewDeaths, (SUM(cast(new_deaths as int))/sum(new_cases))*100 as PercentOfNewCasesThatDied
FROM PortfolioProject . .CovidDeaths$
where continent is not null 
order by 1,2 

-- join deaths and vaccinations
select *
from PortfolioProject . .CovidDeaths$ dea
join PortfolioProject . . CovidVaccinations$ vac
	on dea.location = vac.location
	and dea.dates = vac.dates

-- total population vs vaccination
select dea.continent, dea.location, dea.dates, dea.population, vac.new_vaccinations
, SUM(convert(bigint,vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.dates) as RollingVacinations-- necessary for it to make new count at each location and the order by makes it add up as it goes in order
from PortfolioProject . .CovidDeaths$ dea
join PortfolioProject . . CovidVaccinations$ vac
	on dea.location = vac.location
	and dea.dates = vac.dates
where dea.continent is not null
and dea.location = 'United Kingdom'
order by 2,3
 
--use a CTE
with popvsvac (Continent, Location, dates, population, new_vaccinations, RollingPeopleVaccinated)
as 
(
-- total population vs vaccination
select dea.continent, dea.location, dea.dates, dea.population, vac.new_vaccinations
, SUM(convert(bigint,vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.dates) as RollingPeopleVaccinated-- necessary for it to make new count at each location and the order by makes it add up as it goes in order
from PortfolioProject . .CovidDeaths$ dea
join PortfolioProject . . CovidVaccinations$ vac
	on dea.location = vac.location
	and dea.dates = vac.dates
where dea.continent is not null
and dea.location = 'United Kingdom'
) -- doesnt seem to want to okay this without the proceeding query
select *, (RollingPeopleVaccinated/population)*100 -- wamted to do this in the previous query but couldnt because you cant call something you ev just named without using cte 
From PopvsVac
--no of columns in the cte (with) must match the number in the select 

--Temp Table - same effect as CTE
DROP table if exists #PercentPopulationVaccinated -- drops the table if we've already run it once
create table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
dates datetime, 
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)
Insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.dates, dea.population, vac.new_vaccinations
, SUM(convert(bigint,vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.dates) as RollingPeopleVaccinated-- necessary for it to make new count at each location and the order by makes it add up as it goes in order
from PortfolioProject . .CovidDeaths$ dea
join PortfolioProject . . CovidVaccinations$ vac
	on dea.location = vac.location
	and dea.dates = vac.dates
where dea.continent is not null
and dea.location = 'United Kingdom'

select *, (RollingPeopleVaccinated/population)*100 as RollingPercentVaccinated
From #PercentPopulationVaccinated

--making a view to store data for later visualisation
create view PercentPopulationVaccinated as
select dea.continent, dea.location, dea.dates, dea.population, vac.new_vaccinations
, SUM(convert(bigint,vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.dates) as RollingPeopleVaccinated-- necessary for it to make new count at each location and the order by makes it add up as it goes in order
from PortfolioProject . .CovidDeaths$ dea
join PortfolioProject . . CovidVaccinations$ vac
	on dea.location = vac.location
	and dea.dates = vac.dates
where dea.continent is not null
and dea.location = 'United Kingdom'


