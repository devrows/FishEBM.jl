"""
  Package: FishEBM
  File: agents.jl
  Justin Angevaare, Devin Rose
  Functions for agent-level model components
  Created: May 2015
"""


#Return: Vector(EnviroAgent)
function AgentDB(enviro::EnvironmentAssumptions)
  """
    Description: A function to create an empty agent database for the specified
      simulation length.
    Precondition: None
    Last update: March 2016
  """
  #Initialize the database
  agent_db = [EnviroAgent(0)]; init = false;
  length = (size(enviro.habitat)[1])*(size(enviro.habitat)[2])

  #Push new agents into the database for each enviro location
  for i = 1:length
    if enviro.habitat[i] > 0
      if init == false
        agent_db[1].locationID = i
        init = true
      else
        push!(agent_db, EnviroAgent(i))
      end
    end
  end

  return agent_db
end


#Return: Int64
function findCurrentStage(current_week::Int64, spawn_week::Int64, growth_age::Vector)
  """
    Description: Function used to find the current life stage of a cohort from
      the current age using the agent assumptions growth vector.
    Precondition: None
    Last update: May 2016
  """
  #Initialize the life stage number to 4
  currentStage = 4
  q = length(growth_age)-1
  current_age = current_week - spawn_week

  #Most cohorts are likely to be adults, thus check stages from old to young
  while q > 0 && current_age < growth_age[q]
    currentStage = q
    q-=1
  end

  return currentStage
end


#Add a function for getStageVector(::EnviroAgent, ::AgentAssumptions, curr_week::Int64)


#Return: Vector
function injectAgents!(agent_db::Vector, spawn_agents::Vector, new_stock::Int64, week_num::Int64)
  """
    Description: This function injects agents into the environment, this is
      function is mainly used for adding agents to the environment to test new
      functions.
    Precondition: The new_stock vector cannot have more elements than life
      stages.
    Last update: May 2016
  """
  @assert(length(new_stock)<=4, "There can only by four independent life stages of fish.")

  addToEach = round(Int, floor(new_stock/length(spawn_agents)))
  leftOver = new_stock%length(spawn_agents)
  randomAgent = rand(1:length(spawn_agents))

  #add a new population class to every agent
  for agentRef = 1:length(agent_db)
    push!((agent_db[agentRef]).alive, 0)
    push!((agent_db[agentRef]).weekNum, week_num)
  end

  #Only adds agents to the last (newest) cohort in the agent db spawn locations
  classLength = length((agent_db[1]).weekNum)
  for agentNum = 1:length(spawn_agents)
    addToAgent = addToEach
    if agentNum == randomAgent
      addToAgent += leftOver
    end

    (agent_db[spawn_agents[agentNum]]).alive[classLength] = addToAgent
  end

  return agent_db
end


#Return: Vector (acts directly on agent_db)
function spawn!(agent_db::Vector, adult_a::AdultAssumptions, age_assumpt::AgentAssumptions, enviro_a::EnvironmentAssumptions, week::Int64, carryingcapacity::Float64)
  """
    Description:  This function generates a brood size and location based on
    specific carrying capacities and compensatory values.

    Last update: June 2016
  """
  adult_pop = 0
  #Gets population of all spawning fish
  for i = 2:8
    adult_pop += getPopulationOfAge(i, week, agent_db, age_assumpt, enviro_a)
  end

  if isnan(adult_a.fecunditycompensation)
    compensation_factor_a = 1
  else
    compensation_factor_a = 2*(1-cdf(Normal(carryingcapacity, carryingcapacity/adult_a.fecunditycompensation), adult_pop))
  end

  @assert(0.01 < compensation_factor_a < 1.99, "Population regulation has failed, respecify simulation parameters")

  if isnan(adult_a.maturitycompensation)
    compensation_factor_b = 1
  else
    compensation_factor_b = 2*(1-cdf(Normal(carryingcapacity, carryingcapacity/adult_a.maturitycompensation), adult_pop))
  end

  @assert(0.01 < compensation_factor_b < 1.99, "Population regulation has failed, respecify simulation parameters")

  brood_size = rand(Poisson(compensation_factor_a*adult_a.broodsize[1]), rand(Binomial(getPopulationOfAge(2, week, agent_db, age_assumpt, enviro_a), cdf(Binomial(length(adult_a.broodsize)+2, min(1, compensation_factor_b*adult_a.halfmature/(length(adult_a.broodsize)+2))), 2)*0.5)))

  for i = 2:length(adult_a.broodsize)
    append!(brood_size, rand(Poisson(compensation_factor_a*adult_a.broodsize[i]), rand(Binomial(getPopulationOfAge(i + 2, week, agent_db, age_assumpt, enviro_a), cdf(Binomial(length(adult_a.broodsize)+2, min(1, compensation_factor_b*adult_a.halfmature/(length(adult_a.broodsize)+2))), i + 1)*0.5))))
  end
  brood_location = sample(find(enviro_a.spawningHash), length(brood_size))

  for i = 1:length(agent_db)
    push!((agent_db[i]).alive, 0)
    push!((agent_db[i]).weekNum, week)
  end

  classLength = length((agent_db[1]).weekNum)
  for i = 1:length(brood_size)
    agent_db[enviro_a.spawningHash[brood_location[i]]].alive[classLength] = brood_size[i]
  end

  return agent_db
end


function getPopulationOfAge(age::Int64, current_week::Int64, agent_db::Vector, a_a::AgentAssumptions, e_a::EnvironmentAssumptions)
  """
    Description:  Used for getting the spawning population. This function returns
    the total population of fish in the spawning area of a specified age.

    Last update: June 2016
  """
  classLength = length((agent_db[1]).weekNum)
  pop = 0
  for i = 1:length(e_a.spawningHash)
    if (isEmpty(agent_db[e_a.spawningHash[i]]) == false)
      for j = 1:classLength
        if findCurrentStage(current_week, agent_db[e_a.spawningHash[i]].weekNum[j], a_a.growth) == 4
          if age == 8
            #Find population of fish of age 8 or higher since they all have the same age-specific fecundity
            if floor((current_week - agent_db[e_a.spawningHash[i]].weekNum[j]) / 52) >= age
              pop += agent_db[e_a.spawningHash[i]].alive[j]
            end
          else
            if floor((current_week - agent_db[e_a.spawningHash[i]].weekNum[j]) / 52) == age
              pop += agent_db[e_a.spawningHash[i]].alive[j]
            end #if floor
          end #if age == 8
        end #findCurrentStage
      end #for j=1:classLength
    end #if isEmpty
  end #for i=1:length spawningHash

  return pop
end


#Return: Vector (acts directly on agent_db)
function kill!(agent_db::Vector, e_a::EnvironmentAssumptions, a_a::AgentAssumptions, current_week::Int64)
  """
    Description:  This function generates a mortality based on the stage of the
      fish and its corresponding natural mortality and its location within the
      habitat as described in EnvironmentAssumptions.
    Precondition: None
    Last update: May 2016
  """
  classLength = length((agent_db[1]).weekNum)

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
          killed = rand(Binomial(agent_db[i].alive[j], a_a.naturalmortality[habitat, stage]))
          agent_db[i].killed[stage] += killed #This SHOULD add the number of killed fish to the vector, but doesn't...
          agent_db[i].alive[j] -= killed
          if agent_db[i].alive[j] > 0
            if in(agent_db[i].locationID, e_a.risk)
              killed = rand(Binomial(agent_db[i].alive[j], a_a.extramortality[stage]))
              agent_db[i].killed[stage] += killed
              agent_db[i].alive[j] -= killed
            end
          end
        end
      end
    end
  end

  return agent_db
end


#Returns: operates directly on agent_db
function move!(agent_db::Vector, agent_a::AgentAssumptions,
  enviro_a::EnvironmentAssumptions, current_week::Int64)
  """
    Description: This function uses known information from the environment
      surrounding each agent as well as known movements to move agents around
      the environment during runtime.
    Precondition: Movement autonomy must be between 0 and 1.
    Last update: May 2016
  """
  #@assert(0.<= agent_a.autonomy[stage] <=1., "Autonomy level for stage $stage must be between 0 and 1")

  #put this in environment assumptions when running initEnvironment()
  idToAgentNum = Array(Int64, length(agent_db))
  for age = 1:length(agent_db)
    idToAgentNum[age] = agent_db[age].locationID
  end

  lifeStages = Array(Int64, length(agent_db[1].alive)); lifeStages[:] = 0;
  totalHeight = size(enviro_a.habitat)[1]

  stageWeeks = [agent_a.growth[4], agent_a.growth[3], agent_a.growth[2], agent_a.growth[1]]

  #find the age and stage of each current cohort
  for m = 1:length(lifeStages)
    lifeStages[m] = findCurrentStage(current_week, agent_db[1].weekNum[m], agent_a.growth)
  end

  #For each agent
  for n = 1:length(agent_db)
    #simply the location id of the enviro agent
    id = agent_db[n].locationID

    #Check if the enviro agent is empty before preceeding to movement prep
    if isEmpty(agent_db[n]) == false
      #find local movement avalibility
      moveChoices = Array(Float64, 9)
      moveChoices = [
        id-totalHeight-1, id-1, id+totalHeight-1,
        id-totalHeight, id, id+totalHeight,
        id-totalHeight+1, id+1, id+totalHeight+1]

      moveChoices = hcat(moveChoices,[1,2,3,4,5,6,7,8,9])

      #remove all non water choices
      moveChoices = moveChoices[enviro_a.habitat[moveChoices[:,1]] .> 0, :]

      #for each cohort in the agent database
      for cohort = 1:length(lifeStages)
        stage = lifeStages[cohort]
        choices = deepcopy(moveChoices)

        #match the moveChoices with the corresponding movement array
        for moveNum = 1:size(choices)[1]
          choices[moveNum, 2] = (agent_a.movement[stage])[choices[moveNum, 2]]
        end

        #Match natural mortality rate by location, habitat type, and fish age
        choices = hcat(choices, 1-agent_a.naturalmortality[enviro_a.habitat[choices[:,1]], stage])

        #Normalize the choices
        choices[:,2]=choices[:,2]/sum(choices[:,2])
        choices[:,3]=choices[:,3]/sum(choices[:,3])

        moveDistrib = Multinomial(1, choices[:,2]*(1-agent_a.autonomy[stage]) + choices[:,3]*(agent_a.autonomy[stage]))

        for aliveAges = 1:agent_db[n].alive[cohort]
          tester = round(Int, (choices[findfirst(rand(moveDistrib)), 1]))
          newAgentNum = findfirst(idToAgentNum, tester)
          agent_db[n].alive[cohort] -= 1
          agent_db[newAgentNum].alive[cohort] += 1
        end #for alive
      end #for cohort
    end #if empty
  end #for agent
end


#Return: operates directly on age_db
function removeEmptyClass!(age_db::Vector)
  """
    Description: This function is used to remove an empty spawn class once all
      agents in the entire spawn class have been removed.
    Precondition: None
    Last Update: March 2016
  """
  removeClass = true
  for i = 1:length(age_db)
    if (age_db[i]).alive[1] != 0
      removeClass = false
      i = length(age_db)
    end
  end

  if removeClass
    for j = 1:length(age_db)
      shift!((age_db[j]).alive)
      shift!((age_db[j]).weekNum)
    end
  end
end
