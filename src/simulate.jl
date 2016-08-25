"""
  Package: FishEBM
  File: simulate.jl

  Description: Brings together all of the functions necessary for a life cycle
    simulation

  Returns: Vector(EnviroAgent)

  Contributors: Justin Angevaare, Devin Rose

  Last update: August 2016
"""

function simulate(carrying_capacity::Vector, effort::Vector, bump::Vector,
  initStock::Vector, stock_age::Vector, e_a::EnvironmentAssumptions,
  adult_a::AdultAssumptions, age_a::AgentAssumptions; progress=true::Bool,
  plotPopDensity=false::Bool, plotPopDistribution=false::Bool,
  limit=1000000::Int64, simDescription=""::ASCIIString)

  # preconditions
  @assert(all(carrying_capacity .> 0.), "There is at least one negative carrying
    capacity")
  @assert(plotPopDensity == false || plotPopDistribution == false, "Only one
    plot can be run during a simulation")
  @assert(length(initStock) == length(stock_age), "Unmatching vector length for
    initializing the population, stock length = $(length(initStock)) &
    $(length(stock_age))")

  # initialize the agent database and hash the enviro
  years = length(carrying_capacity)
  a_db = AgentDB(e_a); hashEnvironment!(a_db, e_a);
  if plotPopDensity
    popDensity = initPopulationDensity(e_a)
  end

  #initialize the stock with incoming paramaters
  for i = 1:length(initStock)
    injectAgents!(a_db, e_a.spawningHash, initStock[length(initStock)+1-i], stock_age[length(initStock)+1-i])
  end

  stagePopulation = [0,0,0,0]; totalPopulation = 0;
  for j = 1:4
    stagePopulation[j] = getStagePopulation(j, 0, a_db, age_a)
  end

  #Memory allocation for required data storage
  popDataFrame = DataFrame(Week = 0, Stage1 = stagePopulation[1], Stage2 = stagePopulation[2], Stage3 = stagePopulation[3],Stage4 = stagePopulation[4], Total = sum(stagePopulation))
  ageDataFrame = DataFrame(Year = 0, Age2 = 0, Age3 = 0, Age4 = 0, Age5 = 0, Age6 = 0, Age7 = 0, Age8Plus = 0, Total = 0)
  harvestDataFrame = DataFrame(Week = 0, Age2 = 0, Age3 = 0, Age4 = 0, Age5 = 0, Age6 = 0, Age7 = 0, Age8Plus = 0, Total = 0)
  spawnDataFrame = DataFrame(Week = 0, Age2 = 0, Age3 = 0, Age4 = 0, Age5 = 0, Age6 = 0, Age7 = 0, Age8Plus = 0, Total = 0)
  yearlySpawn = DataFrame(Year = 0, Age2 = 0, Age3 = 0, Age4 = 0, Age5 = 0, Age6 = 0, Age7 = 0, Age8Plus = 0, Total = 0)
  killedDataFrame = DataFrame(Week = 0, Natural = 0, Extra = 0, Compensatory = 0, Total = 0)

  bumpvec = fill(0, years)
  bumpvec[1:length(bump)] = bump
  harvest_effort = fill(0., years)
  harvest_effort[1:length(effort)] = effort

  totalPopulation = sum(initStock)

  #initialize the progress meter
  if progress
    progressBar = Progress(years*52, 30, " $totalPopulation total agents, Year 1 (of $years), week 1 of simulation \n", 30)
  end

  spawnMin = 39; harvestMin = 39;

  for y = 1:years
    for w = 1:52

      #get total number of weeks in simulation
      totalWeek = ((y-1)*52)+w

      # age specific population
      ageSpecificPop = fill(0, 7)
      for i = 1:length(a_db)
        for age = 2:8
          ageSpecificPop[age - 1] += getAgeSpecificPop(age, totalWeek, a_db[i].alive, a_db[i].weekNum, age_a)
        end #for age
      end #for i

      totalAdults = sum(ageSpecificPop)

      #update annually
      if w == 1
        push!(ageDataFrame, vcat(y, ageSpecificPop..., sum(ageSpecificPop)))
      end

      if progress
        progressBar.desc = " $totalAdults adults, $totalPopulation total, Year $y (of $years), week $w of simulation "
        next!(progressBar)
      end

      if w == 50
        tic()
      end
      harvest!(harvest_effort[y], totalWeek, a_db, e_a, adult_a, age_a, harvestDataFrame)
      if w == 50
        harvestTime = toq()
      end

      #Spawn can be set to any week(s)
      if w > spawnMin
        if w == 50
          tic()
        end
        spawn!(a_db, adult_a, age_a, e_a, totalWeek, carrying_capacity[y], spawnDataFrame, yearlySpawn)
        if w == 50
          spawnTime = toq()
        end
      else
        push!(spawnDataFrame, (totalWeek, 0, 0, 0, 0, 0, 0, 0, 0))
      end

      #Agents are killed and moved weekly
      push!(killedDataFrame, (totalWeek, 0, 0, 0, 0))
      if w == 50
        tic()
      end
      killAgeSpecific!(a_db, adult_a, ageSpecificPop, carrying_capacity[y], totalWeek, killedDataFrame)
      if w == 50
        killAgeSpec = toq()
      end
      if w == 50
        tic()
      end
      kill!(a_db, e_a, age_a, totalWeek, killedDataFrame)
      if w == 50
        killTime = toq()
      end
      if w == 50
        tic()
      end
      move!(a_db, age_a, e_a, totalWeek)
      if w == 50
        moveTime = toq()
      end

      #update population information
      stagePopulation = [0,0,0,0]; totalPopulation = 0;
      for j = 1:4
        stagePopulation[j] = getStagePopulation(j, totalWeek, a_db, age_a)
      end
      totalPopulation = sum(stagePopulation)
      push!(popDataFrame,(totalWeek,stagePopulation[1],stagePopulation[2],stagePopulation[3],stagePopulation[4], totalPopulation))

      if w == 50
        print("\n\n For year $y, during week 50, \n\t harvestTime = $harvestTime \n\t spawnTime = $spawnTime \n\t killAgeSpec = $killAgeSpec \n\t killTime = $killTime \n\t moveTime = $moveTime \n\n")
      end

      #show a real time plot (every 10 weeks) of agent movement
      if plotPopDensity
        if w == 1 || w%10 == 0
          updatePopulationDensity!(a_db, popDensity)
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
        description = "\n Simulation was stopped in year $y, week $w due to population failure (total population = $totalPopulation, total adults = $totalAdults, population limit = $limit).\n"
        simSummary(adult_a, age_a, a_db, bump, effort, ((length(carrying_capacity))*52), initStock, carrying_capacity, popDataFrame, ageDataFrame, harvestDataFrame, spawnDataFrame, killedDataFrame, description)
        return a_db
      end #population regulation failure
    end #end for week
    #Remove empty cohorts annually
    removeEmptyClass!(a_db)
  end #end for year

  description = "Simulation was successfully completed."
  simSummary(adult_a, age_a, a_db, bump, effort, ((length(carrying_capacity))*52), initStock, carrying_capacity, popDataFrame, ageDataFrame, harvestDataFrame, spawnDataFrame, yearlySpawn, killedDataFrame, description)
  return a_db
end
