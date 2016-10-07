#=
  Package: FishEBM
  File: mortality.jl
  Devin Rose
  Functions for simulating all types of mortality
  Created: June 2016
=#



"""
  Description: Generates a harvest event based on the number of adult fish in
    the current environment. Operates on the 3 basins of Lake Huron, all divided
    into their specific zones.

  Returns: Operates directly on agent_db

  Last Update: October 2016
"""
function harvest!(effort::Float64, current_week::Int64, agent_db::Vector{EnviroAgent}, enviro_a::EnvironmentAssumptions,
  adult_a::AdultAssumptions, agent_a::AgentAssumptions, hdf::DataFrame, zoneData::DataFrame; zonesToHarvest::Vector{Int64}=[0])

  classLength = length((agent_db[1]).weekNum)
  totalHarvested = fill(0, size(adult_a.catchability))
  zoneHarvest = fill(0, 18)

  # These three lines find the seasonal effort based on known harvesting data
  numYears = ceil(current_week/52)
  yearWeek = current_week - (52 * (numYears - 1))
  seasonalEffort = (-0.4*cos((1/4.138)*yearWeek) + 0.6) * effort

  # Find which zones should be harvested based on the time of year
  if zonesToHarvest[1] == 0
    if (yearWeek < 20 || yearWeek > 40)
      zonesToHarvest = [1,2,3,4,5,6]
    else
      zonesToHarvest = [7,8,9,10,11,12,13,14,15,16,17,18]
    end
  end

  for i = 1:length(enviro_a.harvestHash)
    #Check if agent is empty
    if (isEmpty(agent_db[enviro_a.harvestHash[i]]) == false)
      for j = 1:classLength
        #Check if given cohort is an adult population
        if (findCurrentStage(current_week, agent_db[enviro_a.harvestHash[i]].weekNum[j], agent_a.growth)) == 4
          age = getAge(current_week, agent_db[enviro_a.harvestHash[i]].weekNum[j])
          if in(enviro_a.harvestZones[i], zonesToHarvest)
            numHarvest = rand(Binomial(agent_db[enviro_a.harvestHash[i]].alive[j], adult_a.catchability[age - 1]*seasonalEffort))
          else
            numHarvest = rand(Binomial(agent_db[enviro_a.harvestHash[i]].alive[j], adult_a.catchability[age - 1]*(seasonalEffort*0.5)))
          end
          #Add/subtract harvest numbers to appropriate vectors
          agent_db[enviro_a.harvestHash[i]].harvest += numHarvest
          totalHarvested[age - 1] += numHarvest
          zoneHarvest[enviro_a.harvestZones[i]] += numHarvest
          agent_db[enviro_a.harvestHash[i]].alive[j] -= numHarvest
        end #if findCurrentStage
      end #for j
    end #if isEmpty
  end #for i

  push!(hdf, (vcat(current_week, totalHarvested..., sum(totalHarvested))))
  push!(zoneData, (vcat(current_week, zoneHarvest..., sum(zoneHarvest))))
end


"""
  Description:  This function generates a mortality based on the stage of the
    fish and its corresponding natural mortality and its location within the
    habitat as described in EnvironmentAssumptions.

  Returns: Operates directly on agent_db and kdf

  Last update: September 2016
"""
function kill!(agent_db::Vector{EnviroAgent}, e_a::EnvironmentAssumptions, a_a::AgentAssumptions, current_week::Int64, kdf::DataFrame)
  classLength = length((agent_db[1]).weekNum)
  totalNatural = 0
  totalExtra = 0

  for i = 1:length(agent_db)
    #Check if class is empty. If not empty, continue with kill function. Otherwise skip to next agent
    if (isEmpty(agent_db[i]) == false)
      for j = 1:classLength

        #current_age = current_week - agent_db[i].weekNum[j]
        stage = findCurrentStage(current_week, agent_db[i].weekNum[j], a_a.growth)
        if agent_db[i].alive[j] > 0
          habitat = e_a.habitat[agent_db[i].locationID]

          #Number of fish killed follows binomial distribution with arguments of number of fish alive
          #and natural mortality in the form of a probability
          killedNatural = rand(Binomial(agent_db[i].alive[j], a_a.naturalmortality[habitat, stage]))
          agent_db[i].killedNatural[stage] += killedNatural
          totalNatural += killedNatural
          agent_db[i].alive[j] -= killedNatural
          if agent_db[i].alive[j] > 0
            if in(agent_db[i].locationID, e_a.risk) #Check if this particular locationID is in risk zone
              killedExtra = rand(Binomial(agent_db[i].alive[j], a_a.extramortality[stage]))
              agent_db[i].killedExtra[stage] += killedExtra
              totalExtra += killedExtra
              agent_db[i].alive[j] -= killedExtra
            end #if risk
          end #if agent_db[i].alive (inner)
        end #if agent_db[i].alive (outer)
      end #for j=1:classLength
    end #if isEmpty
  end #for i=1:length(agent_db)

  kdf[size(kdf)[1], 2] = totalNatural
  kdf[size(kdf)[1], 3] = totalExtra

  return agent_db
end


"""
  Description: This function applies transition probabilities to the adult fish
    population to regulate the adult age distribtion.

  Returns: Operates directly on agent_db

  Last update: October 2016
"""
function killAgeSpecific!(agent_db::Vector{EnviroAgent}, adult_a::AdultAssumptions, age_specific_pop::Vector{Int64},
  year_specific_cc::Float64, current_week::Int64, kdf::DataFrame)

  totalKilled = 0

  stockSize = fill(0, size(adult_a.naturalmortality))
  ageVector = fill(0, length(agent_db[1].weekNum))
  mortalityRate = fill(0., length(age_specific_pop))

  if isnan(adult_a.mortalitycompensation)
    compensation_factor = 1
  else
    compFactor = 2*(cdf(Normal(year_specific_cc, year_specific_cc/adult_a.mortalitycompensation), sum(age_specific_pop)))
  end

  @assert(0.0 <= compFactor <= 2.0, "Population regulation failed in killAgeSpecific!, respecify simulation parameters. Expected:0.0-2.0, Received:$compFactor")

  #find dynamic stock sizes
  for i = 1:(length(adult_a.naturalmortality))
    stockSize[i] = rand(Binomial(age_specific_pop[i], 1-adult_a.naturalmortality[i]*compFactor))
  end

  #Find desired mortality rates for dynamic stock sizes
  for j = 1:length(age_specific_pop)
    if age_specific_pop[j] != 0
      mortalityRate[j] = 1-(stockSize[j]/age_specific_pop[j])
    end
  end

  #Find the age (in years) of each adult cohort
  for i = 1:length(ageVector)
    ageVector[i] = getAge(current_week, agent_db[1].weekNum[i])
  end

  for j = 1:length(agent_db)
    if (isEmpty(agent_db[j]) == false)
      k = 1
      while ageVector[k] > 1 && k < length(ageVector)
        estimatedMortality = adult_a.naturalmortality[ageVector[k]-1]
        if ageVector[k] == 8
          overAge = floor((current_week-agent_db[1].weekNum[k])/52)
          ageEffect = overAge-7
          estimatedMortality = ageEffect*estimatedMortality

          if estimatedMortality > 1.0
            estimatedMortality = 1.0
          end # if est.mort > 1
        end
        killedAdult = rand(Binomial(agent_db[j].alive[k], estimatedMortality))

        agent_db[j].alive[k] -= killedAdult
        totalKilled += killedAdult

        k+=1
      end # while adult cohort
    end # if empty
  end # for agent_db

  kdf[size(kdf)[1], 4] = totalKilled

end
