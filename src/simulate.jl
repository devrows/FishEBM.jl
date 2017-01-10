"""
  Package: FishEBM
  File: simulate.jl

  Description: Brings together all of the functions necessary for a life cycle
    simulation

  Returns: Vector(EnviroAgent)

  Contributors: Justin Angevaare, Devin Rose

  Last update: October 2016
"""

function simulate(carrying_capacity::Vector{Float64}, effort::Vector{Int64}, initStock::Vector{Int64},
  stock_age::Vector{Int64}, e_a::EnvironmentAssumptions, adult_a::AdultAssumptions,
  age_a::AgentAssumptions; progress::Bool=true, plotPopDensity::Bool=false,
  plotPopDistribution::Bool=false, limit::Int64=1000000, simDescription::ASCIIString="")

  # preconditions
  @assert(all(carrying_capacity .> 0.), "There is at least one negative carrying capacity")
  @assert(plotPopDensity == false || plotPopDistribution == false, "Only one plot can be run during
    a simulation")
  @assert(length(initStock) == length(stock_age), "Unmatching vector length for initializing the
    population, stock length = $(length(initStock)) & $(length(stock_age))")

  # initialize agent db and hash the enviro
  years = length(carrying_capacity)
  a_db = AgentDB(e_a); hashEnvironment!(a_db, e_a);
  if plotPopDensity
    popDensity = initPopulationDensity(e_a)
  end

  #initialize the stock with incoming paramaters
  for i = 1:length(initStock)
    injectAgents!(a_db, e_a.spawningHash, initStock[length(initStock)+1-i], stock_age[length(initStock)+1-i])
  end

  #Memory allocation for population data storage
  stageDataFrame = DataFrame(Week = 0, Stage1 = 0, Stage2 = 0, Stage3 = 0, Stage4 = 0, Total = 0)
  adultDataFrame = DataFrame(Week = 0, Age2 = 0, Age3 = 0, Age4 = 0, Age5 = 0, Age6 = 0, Age7 = 0, Age8Plus = 0, Total = 0)

  #Memory allocation for mortality data storage (includes harvest)
  harvestDataFrame = DataFrame(Week = 0, Age2 = 0, Age3 = 0, Age4 = 0, Age5 = 0, Age6 = 0, Age7 = 0, Age8Plus = 0, Total = 0)
  harvestZoneData = DataFrame(Week = 0, z1 = 0, z2 = 0, z3 = 0, z4 = 0, z5 = 0, z6 = 0, z7 = 0, z8 = 0, z9 = 0, z10 = 0,
                              z11 = 0, z12 = 0, z13 = 0, z14 = 0, z15 = 0, z16 = 0, z17 = 0, z18 = 0, Total = 0)
  killedDataFrame = DataFrame(Week = 0, Natural = 0, Extra = 0, Compensatory = 0, Total = 0)

  #Memory allocation for spawning data storage
  spawnDataFrame = DataFrame(Week = 0, Age2 = 0, Age3 = 0, Age4 = 0, Age5 = 0, Age6 = 0, Age7 = 0, Age8Plus = 0, Total = 0)


  harvest_effort = fill(0., years)
  harvest_effort[1:length(effort)] = effort

  totalPopulation = sum(initStock)

  #initialize the progress meter
  if progress
    progressBar = Progress(years*52, 30, " $totalPopulation total agents, Year 1 (of $years), week 1 of simulation \n", 30)
  end

  # Specify the final week before beginning harvest season
  spawnMin = 39

  for y = 1:years
    for w = 1:52
      # Find total number of weeks passed in the simulation
      totalWeek = ((y-1)*52)+w

      # age specific population
      ageSpecificPop = fill(0, 7)
      for i = 1:length(a_db)
        for age = 2:8
          ageSpecificPop[age - 1] += getAgeSpecificPop(age, totalWeek, a_db[i].alive, a_db[i].weekNum, age_a)
        end #for age
      end #for i

      totalAdults = sum(ageSpecificPop)

      push!(adultDataFrame, vcat(totalWeek, ageSpecificPop..., sum(ageSpecificPop)))

      if progress
        progressBar.desc = " $totalAdults adults, $(ageSpecificPop[7]) age 8+, $totalPopulation total, Year $y (of $years), week $w of simulation "
        next!(progressBar)
      end

      # Harvest is all year but has peak periods
      harvest!(harvest_effort[y], totalWeek, a_db, e_a, adult_a, age_a, harvestDataFrame, harvestZoneData)

      #Spawn can be set to any week(s)
      if w > spawnMin
        spawn!(a_db, adult_a, age_a, e_a, totalWeek, carrying_capacity[y], spawnDataFrame)
      else
        push!(spawnDataFrame, (totalWeek, 0, 0, 0, 0, 0, 0, 0, 0))
      end

      #Agents are killed and moved weekly
      push!(killedDataFrame, (totalWeek, 0, 0, 0, 0))
      killAgeSpecific!(a_db, adult_a, ageSpecificPop, carrying_capacity[y], totalWeek, killedDataFrame)

      kill!(a_db, e_a, age_a, totalWeek, killedDataFrame)

      # Update agent locations weekly
      move!(a_db, age_a, e_a, totalWeek)

      #update population information
      stagePopulation = [0,0,0,0]; totalPopulation = 0;
      for j = 1:4
        stagePopulation[j] = getStagePopulation(j, totalWeek, a_db, age_a)
      end
      totalPopulation = sum(stagePopulation)

      push!(stageDataFrame, vcat(totalWeek,stagePopulation..., sum(stagePopulation)))

      #show a real time plot (every 10 weeks) of agent movement
      if plotPopDensity
        if w == 1 || w%10 == 0
          updatePopulationDensity!(a_db, popDensity, totalWeek)
          popPlot = spy(popDensity, Guide.title("Year = $y, week = $w, totalPop=$totalPopulation, totalAdult=$totalAdults"))
          display(popPlot)
        end
      end

      #show a real time plot (every 10 weeks) of adult age distribution
      if plotPopDistribution
        if w ==1 || w%10 == 0
          adultAge = [2,3,4,5,6,7,8]
          ageDistPlot = Gadfly.plot(x=adultAge, y=ageSpecificPop, Geom.point,
            Guide.xlabel("Adult age in years"), Guide.ylabel("Adult population"),
            Guide.title("Age Distribution Plot of Adult fish by age,\n y = $y, w = $w, totalPopulation = $totalPopulation"))
          display(ageDistPlot)
        end
      end

      #simulation failure protocol
      if totalPopulation == 0 || totalAdults > limit
        #simply for finishing the progress meter loops
        if progress
          for year = y:years
            for week = 1:52
              progressBar.desc = " $totalAdults adults, $totalPopulation total, Year $y (of $years), week $w of simulation "
              next!(progressBar)
            end
          end
        end

        removeEmptyClass!(a_db)
        description = string("\nSimulation population failure in year $y, week $w (total population
          = $totalPopulation, total adults = $totalAdults, population limit = $limit).\n\n", simDescription)

        simSummary(adult_a, age_a, a_db, effort, ((length(carrying_capacity))*52), initStock, carrying_capacity,
                  stageDataFrame, adultDataFrame, harvestDataFrame, harvestZoneData, spawnDataFrame, killedDataFrame, description)
        return a_db
      end #population regulation failure
    end #end for week
    #Remove empty cohorts annually
    removeEmptyClass!(a_db)
  end #end for year

  description = string("\nSimulation was successfully completed.\n\n", simDescription)

  simSummary(adult_a, age_a, a_db, effort, ((length(carrying_capacity))*52), initStock,
    carrying_capacity, stageDataFrame, adultDataFrame, harvestDataFrame, harvestZoneData,
    spawnDataFrame, killedDataFrame, description)

  return a_db
end
