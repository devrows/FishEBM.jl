#=
  Package: FishEBM
  File: FishEBM.jl
  Justin Angevaare, Devin Rose
  Module definition for an agent-based model
  Created: May 2015
=#

module FishEBM

  #Packages used by this package
  using DataArrays, DataFrames, Distributions, Gadfly, ProgressMeter

  export
    # agents.jl functions
    AgentDB,
    findCurrentStage,
    injectAgents!,
    getAgeSpecificPop,
    getStagePopulation,
    getCohortNumber,
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
    harvestData,
    spawnData,
    killedData,
    simSummary,

    # mortality.jl
    harvest!,
    kill!,

    # move.jl
    move!,

    # simulate.jl functions
    simulate,

    #spawn.jl
    spawn!,

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
    include("mortality.jl")
    include("move.jl")
    include("simulate.jl")
    include("spawn.jl")
    include("utilities.jl")
    include("FileIO.jl")
end
