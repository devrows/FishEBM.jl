#=
  Package: FishEBM
  File: agents.jl
  Justin Angevaare, Devin Rose
  Functions for agent-level model components used by other functions
  Created: May 2015
=#


"""
  Description: A function to create an empty agent database for the specified
    simulation length.

  Returns: Vector(EnviroAgent)

  Last update: March 2016
"""
function AgentDB(enviro::EnvironmentAssumptions)
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


"""
  Description: Function used to find the current life stage of a cohort from
    the current age using the agent assumptions growth vector.

  Returns: Int64

  Last update: May 2016
"""
function findCurrentStage(current_week::Int64, spawn_week::Int64, growth_age::Vector{Int64})
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


"""
  Description: Returns age of cohort. If cohort is not adult, returns 0.

    Returns: Int64

  Last Update: July 2016
"""
function getAge(current_week::Int64, spawn_week::Int64)
  age = floor((current_week - spawn_week)/52)
  if age < 2
    return 0
  elseif age > 8
    return 8
  else
    return Int(age)
  end
end


"""
  Description: Returns population of a specific age in an environment agent.
    Used for functions that requires age-specific population to be taken into
    account (such as spawning or harvest).

    Returns: Int64

  Last Update: June 2016
"""
function getAgeSpecificPop(age::Int64, current_week::Int64, alive::Vector{Int64}, weekNum::Vector{Int64}, a_a::AgentAssumptions)
  @assert(2 <= age <= 8, "Age argument must be between 2 and 8, inclusive (age = $age was passed).")
  classLength = length(weekNum)
  pop = 0
  for i = 1:classLength
    if findCurrentStage(current_week, weekNum[i], a_a.growth) == 4
      if age == 8
        if floor((current_week - weekNum[i]) / 52) >= age
          pop += alive[i]
        end
      else
        if floor((current_week - weekNum[i]) / 52) == age
          pop += alive[i]
        end #if floor
      end #if age == 8 else
    end #findCurrentStage
  end #for i = 1:classLength

  return pop
end


"""
  Description: Returns index of cohort of specified age. Used in harvest! to
    determine which cohort to subtract the harvest size from. If no cohort exist
    for the specified age, function will return 0 and so calling function should
    check if this function returns 0.

  Returns: Int64

  Last Update: June 2016
"""
function getCohortNumber(age::Int64, current_week::Int64, weekNum::Vector{Int64})
  classLength = length(weekNum)
  for i = 1:classLength
    if floor((current_week - weekNum[i]) / 52) == age
      return i
    end #if floor
  end #for i

  return 0
end


"""
  Description:  Used to get population of any of the stages (egg, larva,
    juvenile, adult). Will only return population of one stage at a time. To
    get total population of fish, loop through for i = 1:4.

  Returns: Int64

  Last update: June 2016
"""
function getStagePopulation(stage::Int64, current_week::Int64, agent_db::Vector{EnviroAgent}, a_a::AgentAssumptions)

  classLength = length((agent_db[1]).weekNum)
  pop = 0
  for i = 1:length(agent_db)
    if (isEmpty(agent_db[i]) == false)
      for j = 1:classLength
        if findCurrentStage(current_week, agent_db[i].weekNum[j], a_a.growth) == stage
          pop += agent_db[i].alive[j]
        end #findCurrentStage
      end #for j=1:classLength
    end #if isEmpty
  end #for i=1:length

  return pop
end


"""
  Description: This function is used for efficiently finding the Agent number
    from a known environment id.

  Returns: Int64

  Last update: June 2016
"""
function IDToAgentNum(a_db::Vector{EnviroAgent}, id_num::Int64, max_val::Int64, min_val::Int64)
  testVal = rand(min_val:max_val)

  #uses recursion
  if id_num == a_db[testVal].locationID
    return testVal
  elseif a_db[testVal].locationID > id_num
    testVal = IDToAgentNum(a_db, id_num, testVal, min_val)
  elseif a_db[testVal].locationID < id_num
    testVal = IDToAgentNum(a_db, id_num, max_val, testVal)
  end

  return testVal
end


"""
  Description: This function injects agents into the environment, this is
    function is mainly used for adding agents to the environment to test new
    functions.

    Returns: Operates directly on agent_db

  Last update: May 2016
"""
function injectAgents!(agent_db::Vector{EnviroAgent}, spawn_agents::Vector{Int64}, new_stock::Int64, week_num::Int64)
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
end


"""
  Description: This function is used to remove an empty spawn class once all
    agents in the entire spawn class have been removed.

  Returns: Operates directly on age_db

  Last Update: March 2016
"""
function removeEmptyClass!(age_db::Vector{EnviroAgent})
  if length(age_db[1].alive) > 1
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
      removeEmptyClass!(age_db)
    end
  end
end
