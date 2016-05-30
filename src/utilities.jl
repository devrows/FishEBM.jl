"""
  Package: FishEBM
  File: utilities.jl
  Devin Rose
  Utilities for use of FishEBM
  Created: March 2016
"""

function initPopulationDensity(enviro_a::EnvironmentAssumptions)
  """
    Description: Allocates enough memory for a population density matrix and
      sets all elements in the array to zero.

    Precondition: None

    Last update: May 2016
  """
  popDensity = Array(Int64, size(enviro_a.habitat)[1], size(enviro_a.habitat)[2])

  for i = 1:size(enviro_a.habitat)[1]
    for j = 1:size(enviro_a.habitat)[2]
      popDensity[i, j] = 0
    end
  end

  return popDensity
end


function updatePopulationDensity!(agent_db::Vector, pop_density::Array)
  """
    Description: Updates a population density matrix in the simulate function.
      The population density is used for visualizing the movement of fish during
      the simulation to monitor the behaviour.

    Precondition: A population density matrix is already allocated prior to
      calling this function.

    Last update: May 2016
  """

  for k = 1:length(agent_db)
    pop_density[agent_db[k].locationID] = 1

    for m = 1:length(agent_db[1].alive)
      pop_density[agent_db[k].locationID] += agent_db[k].alive[m]
    end
  end
end