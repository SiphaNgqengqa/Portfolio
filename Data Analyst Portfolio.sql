--##########################################################################
--	AUTHOR: SANELISO MZWAKALI
--	LAST UPDATE: 09/11/2021
--	DESCRIPTION: COVID DATA EXPLORATION
--	SERVER NAME: 
--	DATABASE NAME: PortfolioProject
--##########################################################################

USE [PortfolioProject]

	---------------------------------------------
	-- TRANSFER DATA FROM RAW TO WIP(Work in Progress)
	----------------------------------------------

	drop table [WIP].[CovidDeaths]

	SELECT *
	INTO [WIP].[CovidDeaths]
	FROM [raw].[CovidDeaths]
	--(127817 row(s) affected)


	---------------------------------------------------
	--CONVERT SCIENTIFIC NOTATION BACK TO NUMBERS IN SQL(e+006)
	---------------------------------------------------
	Update [WIP].[CovidDeaths]
	set total_cases = cast(cast(total_cases as float) as int),
	total_deaths = cast(cast(total_deaths as float) as int),
	new_cases = cast(cast(new_cases as float) as bigint),
	population = cast(cast(population as float) as bigint),
	new_deaths = cast(cast(new_deaths as float) as bigint)

	--(127817 row(s) affected)


	-----round off 
	Update [WIP].[CovidDeaths]
	set total_cases = cast(round(cast(total_cases as float),2) as int),
	total_deaths = cast(round(cast(total_deaths as float),2) as int),
	new_cases = cast(round(cast(new_cases as nvarchar),2) as bigint),
	population = cast(round(cast(population as nvarchar),2) as bigint)


	--SELECT DATA THAT WE ARE GOING TO BE USING
	Select location, date, total_cases, date,new_cases,date,total_deaths, population
	from [WIP].[CovidDeaths]
	order by 1,2

	--LOOKING AT TOTAL CASES VS TOTAL DEATHS
	--SHOWS LIKELIHOOD OF DYING IF YOU CONTRACT COVID IN YOUR COUNTRY

	Select location,population, date, total_cases,total_deaths, convert(DECIMAL(15,3),nullif(total_deaths,0))/ convert(DECIMAL(15,3), nullif(total_cases,0)) * 100 AS DeathPercentage
	from [WIP].[CovidDeaths]
	where location like '%south%'
	and continent is not null
	order by 1,2

	--LOOKING AT TOTAL CASES VS POPULATION
	--SHOWS WHAT PERCENTAGE OF POPULATION GOT COVID
	Select location, date,population, total_cases,
	convert(DECIMAL(15,3),nullif(total_cases,0))/ convert(DECIMAL(15,3), nullif(population,0)) * 100 AS PercentagePopulationInfection
	from [WIP].[CovidDeaths]
	--where location like '%south%'
	order by 1,2


	--LOOKING AT COUNTRIES WITH HIGHEST INFECTION RATE COMPARED TO POPULATION

	SELECT location,population, MAX(total_cases),
    MAX(convert(DECIMAL(15,3),nullif(total_cases,0)) / convert(DECIMAL(15,3), nullif(population,0))) * 100 AS PercentagePopulationInfection
	FROM [WIP].[CovidDeaths]
	--where location like '%south%'
	GROUP BY location,population
	ORDER BY PercentagePopulationInfection desc


	--SHOWING COUNTRIES WITH THE HIGHEST DEATH COUNT PER POPULATION
	SELECT location, MAX(Cast(total_deaths as int)) as TotalDeathCount
	FROM [WIP].[CovidDeaths]
	WHERE continent is null
	GROUP BY location
	ORDER BY TotalDeathCount desc


	-----------------------------------------------------------------
	--BREAK THINGS BY CONTINENT
	-----------------------------------------------------------------
	
	--CONTINENTS WITH THE HIGHEST DEATH COUNT PER POPULATION

	SELECT continent, MAX(Cast(total_deaths as int)) as TotalDeathCount
	FROM [WIP].[CovidDeaths]
	WHERE continent is not null
	GROUP BY continent
	ORDER BY TotalDeathCount desc


	--GLOBAL NUMBERS
	Select SUM(CAST(new_cases AS INT))as Total_Cases,
	SUM(CAST(new_deaths AS INT)) as Total_deaths,
	sum(convert(DECIMAL(15,3),nullif(new_deaths,0)))/ sum(convert(DECIMAL(15,3), nullif(new_cases,0))) * 100 as DeathPercentage
	from [WIP].[CovidDeaths]
	--where location like '%south%'
	WHERE continent is not null
	--GROUP BY date
	order by 1,2
	--(1 row(s) affected)


	-------------------------------------------------------------
	--WORKING WITH THE VACCINATION DATA
	-------------------------------------------------------------
	SELECT * 
	FROM [WIP].[CovidVaccinations]
	--(127817 row(s) affected)

	

	---------------------------------------------------
	-- TRANSFER DATA FROM RAW TO WIP(Work in Progress)
	---------------------------------------------------

	drop table [WIP].[CovidVaccinations]

	SELECT * 
	INTO [WIP].[CovidVaccinations]
	FROM [raw].[CovidVaccinations]
	--(127817 row(s) affected)

	--REMOVE TRAILING ZEROS
	Update [WIP].[CovidVaccinations]
	set new_vaccinations = CONVERT(DOUBLE PRECISION,new_vaccinations),
	population = CONVERT(DOUBLE PRECISION,population)
	--(127817 row(s) affected)

	--TOTAL POPULATION VS VACCINATION
	SELECT cd.continent, cd.location, cd.date,cd.population,cv.new_vaccinations,
	SUM(CONVERT(DOUBLE PRECISION,new_vaccinations)) OVER (partition by cd.location Order by cd.location, cv.date)
	As RollingPeopleVaccinated
	FROM [WIP].[CovidDeaths] cd 
	JOIN [WIP].[CovidVaccinations] cv
	on  cd.location = cv.location
	and cd.date = cv.date 
	WHERE cd.continent is not null
	ORDER BY 2,3


	--USE CTE 
	With PopsVac (continent, location, date, population,new_vaccinations, RollingPeopleVaccinated) 
	as
	(
	SELECT cd.continent, cd.location, cd.date,cd.population,cv.new_vaccinations,
	SUM(CONVERT(DOUBLE PRECISION,cv.new_vaccinations)) OVER (partition by cd.location Order by cd.location, cv.date)
	As RollingPeopleVaccinated
	FROM [WIP].[CovidDeaths] cd 
	JOIN [WIP].[CovidVaccinations] cv
	on  cd.location = cv.location
	and cd.date = cv.date 
	WHERE cd.continent is not null
	--and cd.location like '%south%'
	--ORDER BY 2,3
	)
	SELECT *, (RollingPeopleVaccinated)/(nullif(CONVERT(DOUBLE PRECISION,population),0)) * 100 as new
	FROM PopsVac
	--group by continent, location,date,population,new_vaccinations, RollingPeopleVaccinated



	
	------------------------------------------------------------
	--CONVERT SCIENTIFIC NOTATION BACK TO NUMBERS IN SQL(e+006)
	-----------------------------------------------------------
	Update [WIP].[CovidVaccinations]
	set population = cast(cast(population as float) as bigint),
	new_vaccinations = cast(cast(new_vaccinations as float) as bigint)
	
	--(127817 row(s) affected)

	
	select * from [WIP].[CovidVaccinations]

	DROP TABLE #PercentagePopulationVaccinated

	--TEMP TABLE
	CREATE TABLE #PercentagePopulationVaccinated
	(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population nvarchar(255),
	New_vaccination nvarchar(255),
	RollingPeopleVaccinated nvarchar(255)
	)

	insert into #PercentagePopulationVaccinated
	SELECT cd.continent, cd.location, cd.date,cd.population,cv.new_vaccinations,
	SUM(CONVERT(DOUBLE PRECISION,cv.new_vaccinations)) OVER (partition by cd.location Order by cd.location, cv.date)
	As RollingPeopleVaccinated
	FROM [WIP].[CovidDeaths] cd 
	JOIN [WIP].[CovidVaccinations] cv
	on  cd.location = cv.location
	and cd.date = cv.date 
	--WHERE cd.continent is not null
	--and cd.location like '%south%'
	--ORDER BY 2,3
	
	SELECT *, (RollingPeopleVaccinated)/(nullif(CONVERT(DOUBLE PRECISION,population),0))  * 100 as new
	FROM #PercentagePopulationVaccinated


		
	------------------------------------------------------------
	--CREATE VIEW TO STORE DATA FOR VISUALIZATIONS
	------------------------------------------------------------
	CREATE VIEW PercentagePopulationVaccinated as
	SELECT cd.continent, cd.location, cd.date,cd.population,cv.new_vaccinations,
	SUM(CONVERT(DOUBLE PRECISION,cv.new_vaccinations)) OVER (partition by cd.location Order by cd.location, cv.date)
	As RollingPeopleVaccinated
	FROM [WIP].[CovidDeaths] cd 
	JOIN [WIP].[CovidVaccinations] cv
	on  cd.location = cv.location
	and cd.date = cv.date 
	WHERE cd.continent is not null
	--ORDER BY 2,3


	SELECT *
	FROM PercentagePopulationVaccinated

