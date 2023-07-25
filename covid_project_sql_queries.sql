
-----------------------------------------------Covid 19 DATA EXPLORATION----------------------------------------------------------


select * from covid_project..CovidDeaths;  -- total rows : 85171
SELECT * FROM covid_project..CovidVaccinations;

select count(*) from covid_project..CovidDeaths  ---total rows with continent as null : 4111
where continent is null;
-- as there is some vague data in location column having null values in the continent column, 
-- so we will use all the values in continent column which are not null

select count(*) 
from covid_project..CovidDeaths
where continent is not null     



/* Selecting the useful data */

select location, date, total_cases, new_cases, total_deaths, population 
from covid_project..CovidDeaths
where continent is not null      
order by 1,2;

--Q1: What are the total number of countries in the data ?
select count(distinct location )from covid_project..CovidDeaths  -- Answer : 210
where continent is not null;



-- Q2: What is the chance of your death if you are infected by covid--19 in United states?  
Finding (total_deaths/total_cases) in United States*/

select location, date, total_cases, new_cases, total_deaths, population, (total_deaths/total_cases)*100 as death_percentage
from covid_project..CovidDeaths
where location like '%states' 
and continent is not null
order by 1,2; 


-- Q3: List the Countries with Highest Infection Rate compared to Population
-- Answer : We will find the max(total_cases/population)*100 for each location

select location, max(total_cases) as highest_infection_count, population, max(total_cases/population)*100 as infected_percentage
from covid_project..CovidDeaths
where continent is not null
group by location, population
order by infected_percentage desc;

-- Q4: List the Countries with highest Death Count 
-- Answer : We will find max(total_deaths/population)*100

select location,max(cast(total_deaths as int)) as highest_death_count  ---datatype of total_deaths is varchar, hence casting into int then operating
from covid_project..CovidDeaths
where continent is not null
group by location
order by highest_death_count desc; 


-------------------------------- BREAKING THINGS DOWN BY CONTINENT-----------------------------------------

-- Q5: Show the contintents with the highest death count per population

select continent,max(cast(total_deaths as int)) as highest_death_count
from covid_project..CovidDeaths
where continent is not null
group by continent
order by highest_death_count desc; 

                ------- OR--------

select location,max(cast(total_deaths as int)) as highest_death_count
from covid_project..CovidDeaths
where continent is null                       ----- This gives correct values
group by location
order by highest_death_count desc; 



-- Q6:  Globally, how many deaths occured out of total covid-19 cases?

---- Date wise total cases across the globe----

select date,sum(new_cases)as total_cases
from covid_project..CovidDeaths
where continent is not null and total_cases is not null
group by date
order by 1,2;


---- Country-wise total cases across the globe----

select location,sum(new_cases)as total_cases
from covid_project..CovidDeaths
where continent is not null and total_cases is not null
group by location
order by 2 desc;


---- Date-wise Total deaths world -wide---- 

select date, sum(new_cases)as total_cases, sum(cast(new_deaths as int))as total_deaths, 
sum(cast(new_deaths as int))/sum(new_cases)*100 as death_percentage_globally
from covid_project..CovidDeaths
where continent is not null and total_cases is not null
group by date
order by 1,total_cases desc;

-------------------------------------------------

select  sum(new_cases)as total_cases, sum(cast(new_deaths as int))as total_deaths, 
sum(cast(new_deaths as int))/sum(new_cases)*100 as death_percentage_globally
from covid_project..CovidDeaths
where continent is not null;



-----------------------------------------------------------------------------
--Q8: What is the median age of the population infected by covid-19?

select location, max(total_cases) as total_cases, max(total_deaths) as total_deaths, median_age
from covid_project..CovidDeaths
where continent is not null and total_cases is not null and median_age is not null and total_deaths is not null
group by location,median_age
order by median_age desc;

--Q9: What is the median age of the population infected by covid-19?

--provide insights into the association between diabetes and COVID-19, as people with pre-existing conditions like diabetes 
--may be at a higher risk for severe illness or complications if they contract the virus. Analyzing the diabetes prevalence in
--the COVID dataset can help researchers, public health officials, and policymakers understand the impact of diabetes on COVID-19 outcomes 
--and inform appropriate measures for prevention, treatment, and resource allocation.


select death.location, 100*sum(death.new_cases)/max(death.population)as infected_percentage,
sum(cast(death.new_deaths as int))/sum(death.new_cases)*100 as death_percentage, vacc.diabetes_prevalence
from covid_project..CovidDeaths death
join covid_project..CovidVaccinations vacc
on death.location=vacc.location and death.date=vacc.date
where death.continent is not null and total_deaths is not null and vacc.diabetes_prevalence is not null
and death.location !='Vanuatu'
group by death.location, vacc.diabetes_prevalence
order by 4 desc;







----------------------------------------------------------------ADVANCED QUERIES--------------------------------------------------------------------------------

--Q7: Show the rolling Population that is vaccinated (what is cumulative of number of people vaccinated an each date? )


select death.continent, death.location, death.date,death.population, vacc.new_vaccinations,
sum(convert(int,vacc.new_vaccinations)) over (Partition by death.location order by death.location,death.date) as Rolling_People_vaccinated
from covid_project..CovidDeaths as death
join covid_project..CovidDeaths as vacc
on death.location = vacc.location and death.date = vacc.date
where death.continent is not null 
order by 2,3

                                      -----------Solving Q7 by using CTE-------------


With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
select death.continent, death.location, death.date,death.population, vacc.new_vaccinations,
sum(convert(int,vacc.new_vaccinations)) over (Partition by death.location order by death.location,death.date) as Rolling_People_vaccinated
from covid_project..CovidDeaths as death
join covid_project..CovidDeaths as vacc
on death.location = vacc.location and death.date = vacc.date
where death.continent is not null 
--order by 2,3
)


------CTE of RollingPeopleVaccinated is created-------

Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac

                                         -----------Solving Q7 by using TEMP TABLE-------------

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

Insert into #PercentPopulationVaccinated
select death.continent, death.location, death.date,death.population, vacc.new_vaccinations,
sum(convert(int,vacc.new_vaccinations)) over (Partition by death.location order by death.location,death.date) as Rolling_People_vaccinated
from covid_project..CovidDeaths as death
join covid_project..CovidDeaths as vacc
on death.location = vacc.location and death.date = vacc.date
where death.continent is not null 
--order by 2,3


---------------------------Temp table named '#PercentPopulationVaccinated' is created----------------------------
Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated



---------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------CREATING VIEW FOR Rolling_People_vaccinated, so that we can directly it access from here---------------------------------------

create view Rolling_People_vaccinated1
as
select death.continent, death.location, death.date,death.population, vacc.new_vaccinations, vacc.gdp_per_capita,
sum(convert(int,vacc.new_vaccinations)) over (Partition by death.location order by death.location,death.date) as Rolling_People_vaccinated
from covid_project..CovidDeaths as death
join covid_project..CovidDeaths as vacc
on death.location = vacc.location and death.date = vacc.date
where death.continent is not null 
--order by 2,3
----------------------------------------------------------------------------------------------------------------------------------------------------

--Q8: What is the percentage of rolling vaccination per population in 4 countries?

select LOCATION, DATE, new_vaccinations, Rolling_People_vaccinated, 100*(Rolling_People_vaccinated/population) as percent_rolling_people_vaccinated  
from Rolling_People_vaccinated1
where continent is not null 
and (location='India' or location like'%Arab%' or location = 'Russia' or location = 'United States' or location = 'Saudi Arabia')
order by 1,2

----------------------------------------------------------------------------------------------------------------------------------------------------------

--Q9: GDP vs vaccination count

--select * from covid_project..CovidVaccinations;

select LOCATION, gdp_per_capita, max(Rolling_People_vaccinated) as People_vaccinated, (100*max(Rolling_People_vaccinated/population))as percent_people_vaccinated  
from Rolling_People_vaccinated1
where continent is not null 
group by location, gdp_per_capita
having (100*max(Rolling_People_vaccinated/population)) <100
order by percent_people_vaccinated desc 


















