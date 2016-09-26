#=
  Package: FishEBM
  File: spawn.jl
  Devin Rose
  Functions for simulating one week of a spawn season
  Created: June 2016
=#


"""
  Description: Generates a brood size for each spawning location based on number
    of adults in the spawning location, and their age specific fecundity. Brood
    size is affected by a compensation factor based on the total adult
    population in the environment.

  Returns: Operates directly on agent_db

  Last Update: August 2016
"""
function spawn!(agent_db::Vector{EnviroAgent}, adult_a::AdultAssumptions,
  age_assumpt::AgentAssumptions, enviro_a::EnvironmentAssumptions, week::Int64,
  carryingcapacity::Float64, sdf::DataFrame)

  adult_pop = getStagePopulation(4, week, agent_db, age_assumpt)
  totalPop = 0
  for stage = 1:4
    totalPop += getStagePopulation(stage, week, agent_db, age_assumpt)
  end

  if isnan(adult_a.fecunditycompensation)
    compensation_factor_a = 1
  else
    compensation_factor_a = 2*(1-cdf(Normal(carryingcapacity, carryingcapacity/adult_a.fecunditycompensation), totalPop))
  end

  @assert(0.0 <= compensation_factor_a <= 2.0, "Population regulation has failed in spawn (part a), compensation expected:0.0-2.0, actual:$compensation_factor_a")

  if isnan(adult_a.maturitycompensation)
    compensation_factor_b = 1
  else
    compensation_factor_b = 2*(1-cdf(Normal(carryingcapacity, carryingcapacity/adult_a.maturitycompensation), totalPop))
  end

  @assert(0.0 <= compensation_factor_b <= 2.0, "Population regulation has failed in spawn (part b), compensation expected:0.0-2.0, actual:$compensation_factor_a")

  newClass = length(agent_db[1].weekNum)

  #Check if currently in same spawning season as most recent class. If so, continue adding brood to that class.
  #If not, add a new class to each agent and begin adding brood to the new class.
  if week - agent_db[1].weekNum[newClass] > 12
    for i = 1:length(agent_db)
      push!((agent_db[i]).alive, 0)
      push!((agent_db[i]).weekNum, week)
    end
    newClass += 1
  end

  brood_size = fill(0, size(adult_a.broodsize))

  for i = 1:length(enviro_a.spawningHash)
    if isEmpty(agent_db[enviro_a.spawningHash[i]]) == false
      for age = 2:8
        ageSpecificPop = getAgeSpecificPop(age, week, agent_db[enviro_a.spawningHash[i]].alive, agent_db[enviro_a.spawningHash[i]].weekNum, age_assumpt)
        if ageSpecificPop > 1
          #ageSpecificPop/2 implies a 50% male/female ratio, this will be number of females able to lay eggs
          numSpawningAdults = rand(1:ageSpecificPop/2)
          for j = 1:numSpawningAdults
            brood = rand(Poisson(compensation_factor_a*adult_a.broodsize[age - 1]), rand(Binomial(ageSpecificPop, cdf(Binomial(length(adult_a.broodsize)+2, min(1, compensation_factor_b*adult_a.halfmature/(length(adult_a.broodsize)+2))), age)*0.5)))
            for k = 1:length(brood)
              agent_db[enviro_a.spawningHash[i]].alive[newClass] += brood[k]
              brood_size[age - 1] += brood[k]
            end #for k=1:brood
          end #for j = 1:numSpawningAdults
        end #if ageSpecificPop
      end #for ages
    end #if isEmpty
  end #for i=1:length spawningHash

  #Push to weekly spawn number data frame
  push!(sdf, (vcat(week, brood_size..., sum(brood_size))))

end
