#=
  Package: FishEBM.jl
  File: utilities.jl
  Devin Rose
  Utilities for use of FishEBM, plots, memory allocation, etc. during runtime.
  Created: March 2016
=#



"""
  Description: Allocates enough memory for a population density matrix and
    sets all elements in the array to zero.

  Returns: Array(Int64, size of habitat)

  Last update: May 2016
"""
function initPopulationDensity(enviro_a::EnvironmentAssumptions)
  popDensity = Array(Int64, size(enviro_a.habitat)[1], size(enviro_a.habitat)[2])

  for i = 1:size(enviro_a.habitat)[1]
    for j = 1:size(enviro_a.habitat)[2]
      popDensity[i, j] = 0
    end
  end

  return popDensity
end


"""
  Description: Updates a population density matrix in the simulate function.
    The population density is used for visualizing the movement of fish during
    the simulation to monitor the behaviour.

  Precondition: A population density matrix is already allocated prior to
    calling this function.

  Returns: operates directly on pop_density

  Last update: June 2016
"""
function updatePopulationDensity!(agent_db::Vector, pop_density::Array, week_total::Int64)
  totalPop = 0

  # get adult age vector
  ageVec = fill(0, length(agent_db[1].alive))
  for j = 1:length(ageVec)
    ageVec[j] = getAge(week_total, agent_db[1].weekNum[j])
  end

  for k = 1:length(agent_db)
    pop_density[agent_db[k].locationID] = 1

    if isEmpty(agent_db[k]) == false
      for m = 1:length(ageVec)
        if ageVec[m] != 0
          pop_density[agent_db[k].locationID] += agent_db[k].alive[m]
        end
        totalPop += agent_db[k].alive[m]
      end
    end
  end

  return totalPop
end
