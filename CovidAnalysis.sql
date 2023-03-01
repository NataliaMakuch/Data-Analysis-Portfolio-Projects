use Project

-- The highest total number of deaths per country

Select location, max(cast(total_deaths as int)) as DeathCount
From Project..Deaths
where continent is not null 
group by location
order by DeathCount desc

-- The highest total infection rate per country

Select location, max(total_cases) as InfectedCount
From Project..Deaths
where continent is not null 
group by location
order by InfectedCount desc

--Highest total death per population

with DeathvsPopulation (location, DeathCount, Population)
as
(
Select location, max(cast(total_deaths as int)) as DeathsCount, AVG(population) as Population
From Project..Deaths
where continent is not null 
group by location
--order by InfectedCount desc
)
select *, (DeathCount/Population)*100 as DeathCountProcent
from DeathvsPopulation
order by 4 desc

-- Deaths per cases and per population day by day

Select location, date, population, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
, (total_deaths/population)*100 as DeathPercentagePopulation
From Project..Deaths
where continent is not null 
--and location = 'Poland'
order by 1,2


-- Deaths, vaccinations and hospitalizaton in each country around the world

-- Deaths per cases and per population 

Select location, date, population, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
, (total_deaths/population)*100 as DeathPercentagePopulation
From Project..Deaths
where continent is not null 
--and location = 'Poland'
order by 1,2

-- Hospitalization per cases and per population 

Select location, date, population, total_cases, hosp_patients
, (hosp_patients/total_cases)*100 as HospitalizationPercatage
, (hosp_patients/population)*1000 as HospitalizationPromilPopulation
From Project..Deaths
where continent is not null 
--and location = 'Poland'
order by 1,2

-- Vaccinations per cases and per population 
-- No population column in Project..Vaccinations 


Select deaths.location, deaths.date, deaths.population, Deaths.total_cases, Vaccinations.total_vaccinations
, (Vaccinations.total_vaccinations/Deaths.total_cases)*100 as VaccinationPerCases 
, (Vaccinations.total_vaccinations/Deaths.population)*100 as VaccinationPerPopulation
From Project..Deaths
Join Project..Vaccinations
on Deaths.location = Vaccinations.location
and Deaths.date = Vaccinations.date
where deaths.continent is not null 
order by 1,2

-- Total vacciations per day 

Select date, sum(cast(total_vaccinations as bigint)) as TotalVaccinations
From Project..Vaccinations
Where continent is not null
-- and location like '%poland%'
group by date
order by 1

-- Total vacciations per day vs population 

with Vaccinated (Date, TotalVaccinations, Population)
as
(
Select deaths.date, sum(cast(vaccinations.total_vaccinations as bigint)) as TotalVaccinations
, sum(Deaths.population) as population
From Project..Deaths
Join Project..Vaccinations
on Deaths.location = Vaccinations.location
and Deaths.date = Vaccinations.date
Where deaths.continent is not null
-- and location like '%poland%'
group by deaths.date
-- order by 1
)
select *, (TotalVaccinations/Population)*100 as VaccinatedPercent
from Vaccinated
order by Date

-- People fully Vaccinated per date

with Vaccinated (Date, PeopleVaccination, Population)
as
(
Select deaths.date, sum(cast(vaccinations.people_fully_vaccinated as bigint)) as PeopleVaccination
, sum(Deaths.population) as population
From Project..Deaths
Join Project..Vaccinations
on Deaths.location = Vaccinations.location
and Deaths.date = Vaccinations.date
Where deaths.continent is not null
-- and location like '%poland%'
group by deaths.date
-- order by 1
)
select *, (PeopleVaccination/Population)*100 as VaccinatedPercentPerDay
from Vaccinated
order by Date

-- People fully vaccinated percentage per coutry 

with Vaccinated (Location, PeopleVaccination, Population)
as
(
Select deaths.location, max(cast(vaccinations.people_fully_vaccinated as bigint)) as PeopleVaccination
, max(Deaths.population) as population
From Project..Deaths
Join Project..Vaccinations
on Deaths.location = Vaccinations.location
and Deaths.date = Vaccinations.date
Where deaths.continent is not null
group by deaths.location
)
select *, (PeopleVaccination/population)*100 as VaccinatedPercentPerCountry
from Vaccinated
order by VaccinatedPercentPerCountry desc  

-- Checked the differences between people_fully_vaccinated and sum of new_vaccinations 

with SumVaccinated (Location, Date, Population, New_Vaccinations, SumVaccinations, People_Fully_vaccinated)
as
(
Select deaths.location, deaths.date, deaths.population, Vaccinations.new_vaccinations
, SUM(cast(vaccinations.new_vaccinations as bigint)) OVER (Partition by deaths.location order by deaths.location, deaths.date) as SumVaccinations
,Vaccinations.people_fully_vaccinated
From Project..Deaths
Join Project..Vaccinations
on Deaths.location = Vaccinations.location
and Deaths.date = Vaccinations.date
Where deaths.continent is not null
--order by 1,2
)
select *
, (SumVaccinations/population)*100 as SumVaccinationsPerPopulation
, (People_Fully_vaccinated/population)*100 as PeopleFullyVaccinatedPerPopulation
from SumVaccinated
order by Location

-- TABLE to compare values  

Create Table #SummaryTable
(
Continent nvarchar(255), 
Location nvarchar(255), 
Date datetime, 
Population numeric, 
--New_vaccinatios numeric, 
SumVaccinated numeric, 
People_fully_vaccinated numeric
)

Insert into #SummaryTable

Select deaths.continent, deaths.location, deaths.date, deaths.population--, Vaccinations.new_vaccinations
, SUM(cast(vaccinations.new_vaccinations as bigint)) OVER (Partition by deaths.location order by deaths.location, deaths.date) as SumVaccinations
, Vaccinations.people_fully_vaccinated
From Project..Deaths
Join Project..Vaccinations
on Deaths.location = Vaccinations.location
and Deaths.date = Vaccinations.date
Where deaths.continent is not null
--order by 2,3
Select *--, (SumVaccinated/Population)*100 as SumVaccinatedPerPopulation
From #SummaryTable

-- VIEW FOR VISUALISATION

Create View SummaryTable as

Select deaths.continent, deaths.location, deaths.date, deaths.population--, Vaccinations.new_vaccinations
, SUM(cast(vaccinations.new_vaccinations as bigint)) OVER (Partition by deaths.location order by deaths.location, deaths.date) as SumVaccinations
, Vaccinations.people_fully_vaccinated
From Project..Deaths
Join Project..Vaccinations
on Deaths.location = Vaccinations.location
and Deaths.date = Vaccinations.date
Where deaths.continent is not null
