"""
  Package: FishEBM
  File: FishEBM.jl
  Justin Angevaare, Devin Rose
  Module definition for an agent-based model
  Created: May 2015
"""

module FishEBM

  #Packages used by this package
  using DataArrays, DataFrames, Distributions, Gadfly, ProgressMeter

  export
    # agent_stock_interaction.jl functions

    # agents.jl functions
    AgentDB,
    findCurrentStage,
    injectAgents!,
    spawn!,
    getAgeSpecificPop,
    getStagePopulation,
    harvest!,
    getCohortNumber,
    kill!,
    move!,
    removeEmptyClass!,

    # environment.jl functions
    isEmpty,
    hashEnvironment!,
    initEnvironment,
    pad_environment!,

    # FileIO.jl functions
    setProjPath,
    resultsDir,
    dateDir,
    runDir,
    createDir,
    simDir,
    simReadme,
    aliveData,
    simSummary,

    # simulationResults.jl functions

    # simulate.jl functions

    # stock.jl functions

    # types.jl
    AdultAssumptions,
    AgentAssumptions,
    ClassPopulation,
    EnviroAgent,
    EnvironmentAssumptions,

    # utilities.jl functions
    initPopulationDensity,
    updatePopulationDensity!

    #include types.jl in the module first, types are used in various .jl files
    include("types.jl")
    include("agents.jl")
    include("environment.jl")
    include("simulate.jl")
    include("utilities.jl")
    include("FileIO.jl")
end
