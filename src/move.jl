#=
  Package: FishEBM
  File: move.jl
  Devin Rose
  Functions for simulating geographical movement
  Created: June 2016
=#


"""
  Description: This function uses known information from the environment
    surrounding each agent as well as known movements to move agents around
    the environment during runtime.

  Returns: Operates directly on agent_db

  Last update: May 2016
"""
function move!(agent_db::Vector, agent_a::AgentAssumptions,
  enviro_a::EnvironmentAssumptions, current_week::Int64)

  #@assert(0.<= agent_a.autonomy[stage] <=1., "Autonomy level for stage $stage must be between 0 and 1")

  lifeStages = Array(Int64, length(agent_db[1].alive)); lifeStages[:] = 0;
  totalHeight = size(enviro_a.habitat)[1]
  totalEnviroSize = size(enviro_a.habitat)[1]* size(enviro_a.habitat)[2]

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

      #remove all non water and out of enviro choices
      moveChoices = moveChoices[moveChoices[:,1] .> 0, :]
      moveChoices = moveChoices[moveChoices[:,1] .< totalEnviroSize+1, :]
      moveChoices = moveChoices[enviro_a.habitat[moveChoices[:,1]] .> 0, :]

      #for each cohort in the agent database
      for cohort = 1:length(lifeStages)
        stage = lifeStages[cohort]
        choices = deepcopy(moveChoices)

        if stage == 4
          #Create a periodicMovement function for readability
          periodicWeek = current_week%52
          moveX = -5*cosd((180*periodicWeek)/27)+1
          moveY = -5*sind((180*periodicWeek)/27)+1
          moveRadius = sqrt(moveX^2 + moveY^2)
          moveArray = Array(Float64, 3, 3)
          fill!(moveArray, 1.)

          if periodicWeek < 14
            moveArray[2,1] = -moveX
            moveArray[3,1] = moveRadius
            moveArray[3,2] = -moveY
          elseif periodicWeek > 13 && periodicWeek < 27
            moveArray[2,3] = moveX
            moveArray[3,2] = -moveY
            moveArray[3,3] = moveRadius
          elseif periodicWeek > 26 && periodicWeek < 40
            moveArray[1,2] = moveY
            moveArray[1,3] = moveRadius
            moveArray[2,3] = moveX
          elseif periodicWeek > 39
            moveArray[1,1] = moveRadius
            moveArray[1,2] = moveY
            moveArray[2,1] = -moveX
          end
        else
          moveArray = agent_a.movement[stage]
        end

        #match the moveChoices with the corresponding movement array
        for moveNum = 1:size(choices)[1]
          choices[moveNum, 2] = round(Int, moveArray[choices[moveNum, 2]])
        end

        #Match natural mortality rate by location, habitat type, and fish age
        choices = hcat(choices, 1-agent_a.naturalmortality[enviro_a.habitat[choices[:,1]], stage])

        #Normalize the choices
        choices[:,2]=choices[:,2]/sum(choices[:,2])
        choices[:,3]=choices[:,3]/sum(choices[:,3])

        moveDistrib = Multinomial(1, choices[:,2]*(1-agent_a.autonomy[stage])
          + choices[:,3]*(agent_a.autonomy[stage]))

        for aliveAges = 1:agent_db[n].alive[cohort]
          newLocation = round(Int, (choices[findfirst(rand(moveDistrib)), 1]))
          if agent_db[n].locationID != newLocation
            newAgentNum = IDToAgentNum(agent_db, newLocation, length(agent_db), 1)
            agent_db[n].alive[cohort] -= 1
            agent_db[newAgentNum].alive[cohort] += 1
          end #if doesn't move
        end #for all alive
      end #for each cohort
    end #if enviro empty
  end #for number agent
end


#Add a periodic movement function
