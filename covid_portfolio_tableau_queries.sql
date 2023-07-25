
             ----Queries used for Tableau project----
--1:

select sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths 
,100*sum(cast(new_deaths as int)) /sum(new_cases) as Death_Percentage
from covid_project..CovidDeaths
where continent is not null
order by 1,2;

--2: TOTAL DEATH COUNT ACROSS THE GLOBE (continent-wise)

select location, sum(cast(new_deaths as int)) as total_death_count
from covid_project..CovidDeaths
where continent is null 
and location not in ('World', 'European Union', 'International')
group by location
order by total_death_count desc;

--3:

select location, population, max(total_cases) as highest_infection_count, max(total_cases/population)*100 as Infected_percentage_population
from covid_project..CovidDeaths
where continent is not null
group by location, population
order by Infected_percentage_population desc;

--4: 

select location, population, date, max(total_cases) as highest_infection_count, max(total_cases/population)*100 as Infected_percentage_population
from covid_project..CovidDeaths
where continent is not null
group by location, population, date
order by date desc,Infected_percentage_population desc;

--5: What is the median age of the population infected by covid-19?

select location, max(total_cases) as total_cases, max(total_deaths) as total_deaths, median_age
from covid_project..CovidDeaths
where continent is not null and total_cases is not null and median_age is not null and total_deaths is not null
group by location,median_age
order by median_age desc;

--6: What is the median age of the population infected by covid-19?


select death.location, 100*sum(death.new_cases)/max(death.population)as infected_percentage,
sum(cast(death.new_deaths as int))/sum(death.new_cases)*100 as death_percentage, (vacc.diabetes_prevalence)
from covid_project..CovidDeaths death
join covid_project..CovidVaccinations vacc
on death.location=vacc.location and death.date=vacc.date
where death.continent is not null and total_deaths is not null and vacc.diabetes_prevalence is not null
and death.location !='Vanuatu' 
group by death.location, vacc.diabetes_prevalence
order by 4 desc,death_percentage desc;


--7:
--------------------------CREATING VIEW FOR Rolling_People_vaccinated, so that we can directly it access from here---------------------------------------

create view Rolling_People_vaccinated
as
select death.continent, death.location, death.date,death.population, vacc.new_vaccinations,
sum(convert(int,vacc.new_vaccinations)) over (Partition by death.location order by death.location,death.date) as Rolling_People_vaccinated
from covid_project..CovidDeaths as death
join covid_project..CovidDeaths as vacc
on death.location = vacc.location and death.date = vacc.date
where death.continent is not null 
--order by 2,3

select * from Rolling_People_vaccinated
where continent is not null 
and (location='India' or location like'%states%' or location = 'Russia' or location = 'Canada')
order by 1,2