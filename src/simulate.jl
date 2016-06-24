"""
  Package: FishEBM
  File: simulate.jl

  Description: Brings together all of the functions necessary for a life cycle
    simulation

  Returns: Vector(EnviroAgent)

  Contributors: Justin Angevaare, Devin Rose

  Last update: June 2016
"""


function simulate(carrying_capacity::Vector, effort::Vector, bump::Vector,
  initStock::Vector, e_a::EnvironmentAssumptions, adult_a::AdultAssumptions,
  age_a::AgentAssumptions, progress=true::Bool, limit=50000000::Int64,
  plotPopDensity=true::Bool)

  @assert(all(carrying_capacity .> 0.), "There is at least one negative carrying capacity")
  years = length(carrying_capacity)

  #initialize the agent database and hash the enviro
  a_db = AgentDB(e_a); hashEnvironment!(a_db, e_a);
  if plotPopDensity
    popDensity = initPopulationDensity(e_a)
  end

  #initialize the stock with a spawn
  for i = 1:4
    injectAgents!(a_db, e_a.spawningHash, initStock[5-i], -age_a.growth[((7-i)%4)+1])
  end

  popDataFrame = DataFrame(Week = 0, Stage1 = initStock[1], Stage2 = initStock[2], Stage3 = initStock[3],Stage4 = initStock[4], Total = sum(initStock))
  harvestDataFrame = DataFrame(Week = 0, Age2 = 0, Age3 = 0, Age4 = 0, Age5 = 0, Age6 = 0, Age7 = 0, Age8Plus = 0, Total = 0)
  spawnDataFrame = DataFrame(Week = 0, Age2 = 0, Age3 = 0, Age4 = 0, Age5 = 0, Age6 = 0, Age7 = 0, Age8Plus = 0, Total = 0)
  killedDataFrame = DataFrame(Week = 0, Natural = 0, Extra = 0, Total = 0)

  spawn!(a_db, adult_a, age_a, e_a, 1, carrying_capacity[1], spawnDataFrame)

  bumpvec = fill(0, years)
  bumpvec[1:length(bump)] = bump
  harvest_effort = fill(0., years)
  harvest_effort[1:length(effort)] = effort

  totalPopulation = sum(initStock)

  #initialize the progress meter
  if progress
    progressBar = Progress(years*52, 30, " Year 1 (of $years), week 1 of simulation ($totalPopulation adults)) \n", 30)
  end

  spawnMin = 39; harvestMin = 39;

  for y = 1:years
    for w = 1:52

      if progress
        progressBar.desc = " Year $y (of $years), week $w of simulation ($totalPopulation agents) "
        next!(progressBar)
      end

      totalWeek = ((y-1)*52)+w

      ageSpecificPop = fill(0, 7)
      for i = 1:length(a_db)
        for age = 2:8
          ageSpecificPop[age - 1] += getAgeSpecificPop(age, totalWeek, a_db[i].alive, a_db[i].weekNum, age_a)
        end #for age
      end #for i

      #harvest and spawn can be set to any week(s)
      if w > harvestMin
        #harvest can be set to any week(s)
        harvest!(harvest_effort[y], totalWeek, a_db, e_a, adult_a, age_a, harvestDataFrame)
      else
        push!(harvestDataFrame, (totalWeek, 0, 0, 0, 0, 0, 0, 0, 0))
      end

      if w > spawnMin
        spawn!(a_db, adult_a, age_a, e_a, totalWeek, carrying_capacity[y], spawnDataFrame)
      else
        push!(spawnDataFrame, (totalWeek, 0, 0, 0, 0, 0, 0, 0, 0))
      end

      #Agents are killed and moved weekly
      kill!(a_db, e_a, age_a, totalWeek, killedDataFrame)
      move!(a_db, age_a, e_a, totalWeek)

      #update population information
      stagePopulation = [0,0,0,0]; totalPopulation = 0;
      for j = 1:4
        stagePopulation[j] = getStagePopulation(j, totalWeek, a_db, age_a)
      end
      totalPopulation = sum(stagePopulation)
      push!(popDataFrame,(totalWeek,stagePopulation[1],stagePopulation[2],stagePopulation[3],stagePopulation[4], totalPopulation))

      #show a real time plot (weekly) of agent movement
      if plotPopDensity
        if w == 1 || w%10 == 0
          updatePopulationDensity!(a_db, popDensity)
          popPlot = spy(popDensity, Guide.title("Year = $y, week = $w, totalPopulation = $totalPopulation"))
          display(popPlot)
        end
      end

      #if simulation fails
      if totalPopulation == 0 || totalPopulation > limit
        removeEmptyClass!(a_db)
        description = "Simulation was stopped in year $y, week $w due to population failure (total population = $totalPopulation, population limit = $limit)."
        simSummary(adult_a, age_a, a_db, bump, effort, ((length(carrying_capacity))*52), initStock, carrying_capacity, popDataFrame, harvestDataFrame, spawnDataFrame, killedDataFrame, description)
        return a_db
      end

    end #end for week
    #Remove empty cohorts annually
    removeEmptyClass!(a_db)
  end #end for year

  description = "Simulation was successfully completed."
  simSummary(adult_a, age_a, a_db, bump, effort, ((length(carrying_capacity))*52), initStock, carrying_capacity, popDataFrame, harvestDataFrame, spawnDataFrame, killedDataFrame, description)
  return a_db
end
