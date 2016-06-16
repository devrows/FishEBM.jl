"""
  Package: FishEBM
  File: simulate.jl
  Justin Angevaare, Devin Rose
  Brings together all of the functions necessary for a life cycle simulation
  May 2015
"""


function simulate(carrying_capacity::Vector, effort::Vector, bump::Vector,
  initStock::Vector, e_a::EnvironmentAssumptions, adult_a::AdultAssumptions,
  age_a::AgentAssumptions, progress=true::Bool, limit=50000000::Int64)

  @assert(all(carrying_capacity .> 0.), "There is at least one negative carrying capacity")
  years = length(carrying_capacity)

  #initialize the agent database and hash the enviro
  a_db = AgentDB(e_a); hashEnvironment!(a_db, e_a);
  popDensity = initPopulationDensity(e_a)

  #initialize the stock with a spawn
  for i = 1:4
    injectAgents!(a_db, e_a.spawningHash, initStock[5-i], -age_a.growth[((7-i)%4)+1])
  end
  spawn!(a_db, adult_a, age_a, e_a, 1, carrying_capacity[1])

  bumpvec = fill(0, years)
  bumpvec[1:length(bump)] = bump
  harvest_effort = fill(0., years)
  harvest_effort[1:length(effort)] = effort

  totalPopulation = initStock[length(initStock)]

  #initialize the progress meter
  if progress
    progressBar = Progress(years*52, 30, " Year 1 (of $years), week 1 of simulation ($totalPopulation adults)) \n", 30)
  end

  spawnMin = 39; harvestMin = 39;

  for y = 1:years
    spawnWeek = 40
    print("Year = $y \n")
    for w = 1:52
      @assert(totalPopulation < limit, "> $limit agents in current simulation, stopping here.")

      if progress
        progressBar.desc = " Year $y (of $years), week $w of simulation ($totalPopulation) agents) "
        next!(progressBar)
      end

      totalWeek = ((y-1)*52)+w

      #harvest and spawn can be set to any week(s)
      if w > harvestMin
        #harvest can be set to any week(s)
        harvest!(harvest_effort[y], totalWeek, a_db, e_a, adult_a, age_a)
      end

      if w > spawnMin
        spawn!(a_db, aadult_a, age_a, e_a, totalWeek, carrying_capacity[y])
      end

      #Agents are killed and moved weekly
      kill!(a_db, e_a, age_a, totalWeek)
      move!(a_db, age_a, e_a, totalWeek)

      #show a real time plot (weekly) of agent movement
      if w == 1 || w%10 == 0
        totalPopulation = updatePopulationDensity!(a_db, popDensity)
        popPlot = spy(popDensity, Guide.title("Year = $y, week = $w, totalPopulation = $totalPopulation"))
        display(popPlot)
      end

      if totalPopulation == 0
        removeEmptyClass!(a_db)
        return a_db
      end
    end
    #Remove empty cohorts
    removeEmptyClass!(a_db)
  end

  return a_db
end
