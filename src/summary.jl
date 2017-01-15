#=
  Package: FishEBM.jl
  File: summary.jl
  Devin Rose
  Functions used for summarizing the simulation results upon completion
  Created: September 2016
=#


"""
  Description: Function used to generate summary files from an agent datavase for completed
    simulations for archiving and analysis. Saves all available data after a completed simulation.

  Returns: N/A

  Last update: September 2016
"""
function simSummary(adultAssumpt::AdultAssumptions, agentAssumpt::AgentAssumptions,
  agentDB::Vector{EnviroAgent}, effort::Vector{Int64}, finalWeek::Int64, initStock::Vector{Int64},
  carryingCap::Vector{Float64}, stageDataFrame::DataFrame, adultDataFrame::DataFrame,
  harvestDataFrame::DataFrame, harvestZoneData::DataFrame, spawnDataFrame::DataFrame,
  killedDataFrame::DataFrame, userInput::ASCIIString)

  # Find directory for the results
  simDir()
  path = runDir(dateDir(resultsDir(setProjPath())[1])[1])[2]

  # Save all available data from the completed simulation

  # Weekly population (by stage)
  aliveData(stageDataFrame, path)

  # Weekly adult age (by year) distribution
  ageData(adultDataFrame, path)

  # Weekly harvest total by location (harvest zone number) and age
  harvestData(harvestDataFrame, harvestZoneData, path)

  # Weekly spawning total from each age
  spawnData(spawnDataFrame, path)

  # Wekly mortality totals from each layer of mortality
  killedData(killedDataFrame, path)

  # Create a readme file to save the simulation paramaters and description
  simReadme(adultAssumpt, agentAssumpt, effort, initStock, carryingCap, path, userInput)

  # Saving an empty file inside of the run for quickly checking the simulation check
  cd(path)
  touch(userInput)

end
