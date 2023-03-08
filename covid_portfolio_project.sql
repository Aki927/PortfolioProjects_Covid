SELECT * FROM covid_data.CovidVaccinations;

select * from covid_data.CovidDeaths
where location not in ('Africa','Asia','Europe','European Union','High income','International','Low income','Lower middle income','North America','South America','Upper middle income','World','Oceania')
order by 3,4;

-- Select the Data that we are going to be using
select location, date, total_cases, new_cases, total_deaths, population
from covid_data.CovidDeaths
order by 1,2;

-- Look at total cases vs total deaths (Probability of you dying if you contract covid in your country)
select location, date, total_cases, total_deaths, (total_deaths / total_cases)* 100 as death_rate
from covid_data.CovidDeaths
where location like '%states%'
and continent is not null
order by 1,2;

-- Look at total cases vs population (Shows what percentage of population got Covid)
select location, date, total_cases, population, (total_cases/population)* 100 as contraction_rate
from covid_data.CovidDeaths
where location like '%states%'
and continent is not null
order by 1,2;

-- Look at countriest with highest infection rate compared to population 
select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected 
from covid_data.CovidDeaths 
where continent is not null
group by location, population 
order by PercentPopulationInfected desc;


-- Look at countries with highest death count per population
select location, MAX(total_deaths) as TotalDeathCount
from covid_data.CovidDeaths 
where continent != ''
-- where continent = '' -- and location not like '%income'
group by location
order by TotalDeathCount desc;


-- Break things down by continent (incorrect) 
select continent, MAX(total_deaths) as TotalDeathCount
from covid_data.CovidDeaths 
where continent != ''
group by continent
order by TotalDeathCount desc;

-- Break things down by continent (correct) 
select location, MAX(total_deaths) as TotalDeathCount
from covid_data.CovidDeaths 
-- where continent != ''
where continent = '' and location not like '%income'
group by location
order by TotalDeathCount desc;

-- Global Numbers
select date, sum(new_cases) as 'Total Cases', sum(new_deaths) as 'Total Deaths', sum(new_deaths)/sum(new_cases)*100 as 'Death Percentage'
from covid_data.CovidDeaths
where continent != ''
group by date
order by 1,2;

-- Global Numbers (total)
select sum(new_cases) as 'Total Cases', sum(new_deaths) as 'Total Deaths', sum(new_deaths)/sum(new_cases)*100 as 'Death Percentage'
from covid_data.CovidDeaths
where continent != ''
-- group by date
order by 1,2;

-- Query CovidVaccinations
select CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations
from covid_data.CovidDeaths CD
join covid_data.CovidVaccinations CV
	on CD.location = CV.location
    and CD.date = CV.date
-- where CD.continent != '' or CD.location not like '%income'
where CD.location not in ('Africa','Asia','Europe','European Union','High income','International','Low income','Lower middle income','North America','South America','Upper middle income','World','Oceania')
order by 2,3;

-- Look at total population vs vaccinations
select CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations
, SUM(CV.new_vaccinations) OVER (Partition by CD.location order by CD.location, 
	CD.date) as rolling_people_vaccinated
from covid_data.CovidDeaths CD
join covid_data.CovidVaccinations CV
	on CD.location = CV.location
    and CD.date = CV.date
where CD.location not in ('Africa','Asia','Europe','European Union','High income','International','Low income','Lower middle income','North America','South America','Upper middle income','World','Oceania')
order by location, date;


-- Use CTE
With PopvsVac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
as
(
select CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations
, SUM(CV.new_vaccinations) OVER (Partition by CD.location order by CD.location, 
	CD.date) as rolling_people_vaccinated
from covid_data.CovidDeaths CD
join covid_data.CovidVaccinations CV
	on CD.location = CV.location
    and CD.date = CV.date
where CD.location not in ('Africa','Asia','Europe','European Union','High income','International','Low income','Lower middle income','North America','South America','Upper middle income','World','Oceania')
-- order by 2,3
)
select *, (rolling_people_vaccinated/population)*100
from PopvsVac;


-- Use TEMP TABLE
Drop Temporary Table if exists PercentPopulationVaccinated;
Create Temporary Table PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
rolling_people_vaccinated numeric
);

Insert into PercentPopulationVaccinated
select CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations
, SUM(CV.new_vaccinations) OVER (Partition by CD.location order by CD.location, 
	CD.date) as rolling_people_vaccinated
from covid_data.CovidDeaths CD
join covid_data.CovidVaccinations CV
	on CD.location = CV.location
    and CD.date = CV.date
where CD.location not in ('Africa','Asia','Europe','European Union','High income','International','Low income','Lower middle income','North America','South America','Upper middle income','World','Oceania')
order by 2,3
;
select *, (rolling_people_vaccinated/population)*100
from PercentPopulationVaccinated;


-- VIEWS FOR TABLEAU VISUALIZATIONS
Create View PercentPopulationVaccinated as
select CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations
, SUM(CV.new_vaccinations) OVER (Partition by CD.location order by CD.location, 
	CD.date) as rolling_people_vaccinated
from covid_data.CovidDeaths CD
join covid_data.CovidVaccinations CV
	on CD.location = CV.location
    and CD.date = CV.date
where CD.location not in ('Africa','Asia','Europe','European Union','High income','International','Low income','Lower middle income','North America','South America','Upper middle income','World','Oceania')
order by 2,3; 

Create View PercentPopulationInfected as
select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected 
from covid_data.CovidDeaths 
where continent is not null
group by location, population 
order by PercentPopulationInfected desc;

Create View deathcount_by_country as
select location, MAX(total_deaths) as TotalDeathCount
from covid_data.CovidDeaths 
where continent != ''
-- where continent = '' -- and location not like '%income'
group by location
order by TotalDeathCount desc;

Create View deathcount_by_continent as
select location, MAX(total_deaths) as TotalDeathCount
from covid_data.CovidDeaths 
-- where continent != ''
where continent = '' and location not like '%income'
group by location
order by TotalDeathCount desc;

Create View Global_death_percent_bydate as 
select date, sum(new_cases) as 'Total Cases', sum(new_deaths) as 'Total Deaths', sum(new_deaths)/sum(new_cases)*100 as 'Death Percentage'
from covid_data.CovidDeaths
where continent != ''
group by date
order by 1,2;

Create View Totalvaccinations_bydate as
select CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations
from covid_data.CovidDeaths CD
join covid_data.CovidVaccinations CV
	on CD.location = CV.location
    and CD.date = CV.date
-- where CD.continent != '' or CD.location not like '%income'
where CD.location not in ('Africa','Asia','Europe','European Union','High income','International','Low income','Lower middle income','North America','South America','Upper middle income','World','Oceania')
order by 2,3;