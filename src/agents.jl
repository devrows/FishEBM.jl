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


#=
  Tweak this to find the current stage from the current_week and spawn_week
=#
#Add a function for getStageVector(::EnviroAgent, ::AgentAssumptions, curr_week::Int64)

#Return: Int64
function findCurrentStage(current_age::Int64, growth_age::Vector)
  """
    Description: Function used to find the current life stage of a cohort from
      the current age using the agent assumptions growth vector.

    Precondition: None

    Last update: May 2016
  """
  #Initialize the life stage number to 4
  currentStage = 4
  q = length(growth_age)-1

  #Most cohorts are likely to be adults, thus check stages from old to young
  while q > 0 && current_age < growth_age[q]
    currentStage = q
    q-=1
  end

  return currentStage
end


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
