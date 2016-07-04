#=
  Package: FishEBM
  File: mortality.jl
  Devin Rose
  Functions for simulating all types of mortality
  Created: June 2016
=#


#Adding age specific mortality soon for adults


"""
  Description: Generates a harvest size based on total number of age-specific
    fish in the environment. Currently, harvest location is a randomly
    generated vector of locations from the spawningHash. Harvest size is
    divided up into each harvest location.

  Returns: Operates directly on agent_db

  Last Update: June 2016
"""
function harvest!(effort::Float64, week::Int64, agent_db::Vector, enviro_a::EnvironmentAssumptions, adult_a::AdultAssumptions, a_a::AgentAssumptions, hdf::DataFrame)

  harvest_size = fill(0, size(adult_a.catchability))
  ageSpecificPop = fill(0, size(adult_a.catchability))

  #Get total age specific population for each age
  for i = 1:length(agent_db)
    for age = 2:8
      ageSpecificPop[age - 1] += getAgeSpecificPop(age, week, agent_db[i].alive, agent_db[i].weekNum, a_a)
    end #for age
  end #for i

  #Generate harvest size for each age
  for i = 1:length(harvest_size)
    harvest_size[i] = rand(Poisson(ageSpecificPop[i]*adult_a.catchability[i]*effort))
  end

  push!(hdf, (vcat(week, harvest_size..., sum(harvest_size)))) #Add each age specific harvest size to dataframe

  harvest_loc = sample(find(enviro_a.spawningHash), rand(1:10)) #generate random harvest locations

  for age = 2:8 #loop through all ages
    harvestFromEach = round(Int, floor(harvest_size[age - 1] / length(harvest_loc))) #Divide harvest_size by number of harvest locations
    leftOver = harvest_size[age - 1] % length(harvest_loc) #Will subtract leftover from random location
    for i = 1:length(harvest_loc) #loop through all harvest locations
      cohort = getCohortNumber(age, week, agent_db[enviro_a.spawningHash[harvest_loc[i]]].weekNum)
      if cohort == 0 #check if cohort exists
        leftOver += harvestFromEach #If cohort does not exist in agent, add what woud have been their harvest to leftover
      else
        agent_db[enviro_a.spawningHash[harvest_loc[i]]].harvest += harvestFromEach
        agent_db[enviro_a.spawningHash[harvest_loc[i]]].alive[cohort] -= harvestFromEach
        if agent_db[enviro_a.spawningHash[harvest_loc[i]]].alive[cohort] < 0
          harvestFromEach += 0 - agent_db[enviro_a.spawningHash[harvest_loc[i]]].alive[cohort]
          agent_db[enviro_a.spawningHash[harvest_loc[i]]].alive[cohort] = 0
        end #if agent_db
      end #if cohort
    end #for i

    randomAgents = rand(1:length(harvest_loc), leftOver) #Get random samples from harvest_loc depending on how many leftover fish
    for i = 1:length(randomAgents) #loop through all harvest locations
      cohort = getCohortNumber(age, week, agent_db[enviro_a.spawningHash[randomAgents[i]]].weekNum)
      if cohort != 0
        agent_db[enviro_a.spawningHash[harvest_loc[i]]].harvest += 1
        agent_db[enviro_a.spawningHash[harvest_loc[i]]].alive[cohort] -= 1
        if agent_db[enviro_a.spawningHash[harvest_loc[i]]].alive[cohort] < 0
          agent_db[enviro_a.spawningHash[harvest_loc[i]]].alive[cohort] = 0
        end #if agent_db
      end #if cohort
    end #for i=1:length(randomAgents)
  end #for age
end


"""
  Description:  This function generates a mortality based on the stage of the
    fish and its corresponding natural mortality and its location within the
    habitat as described in EnvironmentAssumptions.

  Returns: Operates directly on agent_db and kdf

  Last update: June 2016
"""
function kill!(agent_db::Vector, e_a::EnvironmentAssumptions, a_a::AgentAssumptions, current_week::Int64, kdf::DataFrame)
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

  total = totalNatural + totalExtra

  push!(kdf, (current_week, totalNatural, totalExtra, total))

  return agent_db
end


"""
  Description: This function applies transition probabilities to the adult fish
    population to regulate the adult age distribtion.

  Returns: Operates directly on agent_db

  Last update: June 2016
"""
function killAgeSpecific!(agent_db::Vector, adult_a::AdultAssumptions,
  age_specific_pop::Vector, year_specific_cc::Float64, current_week::Int64)

  stockSize = fill(0, size(adult_a.naturalmortality))
  ageVector = fill(0, length(agent_db[1].weekNum))
  mortalityRate = fill(0., length(age_specific_pop))

  if isnan(adult_a.mortalitycompensation)
    compensation_factor = 1
  else
    compFactor = 2*(cdf(Normal(year_specific_cc, year_specific_cc/adult_a.mortalitycompensation), sum(age_specific_pop)))
  end

  @assert(0.01 < compFactor < 1.99, "Population regulation has failed, respecify simulation parameters")

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
        killedAdult = rand(Binomial(agent_db[j].alive[k], adult_a.naturalmortality[ageVector[k]-1]))
        agent_db[j].alive[k] -= killedAdult

        #add code here for story the compensatory adult mortalities

        k+=1
      end # while adult cohort
    end # if empty
  end # for agent_db
end
