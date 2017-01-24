"""
  Package: FishEBM
  File: FishEBM.jl
  Justin Angevaare, Devin Rose
  Module definition for an enviro-based model
  Created: May 2015
"""

module FishEBM
  # Version number
  VersionNumber = "0.2.0"

  # Packages used by this package
  using DataArrays, DataFrames, Distributions, Gadfly, ProgressMeter

  export
    # agents.jl functions
    AgentDB,
    findCurrentStage,
    getAge,
    getAgeSpecificPop,
    getCohortNumber,
    getStagePopulation,
    injectAgents!,
    removeEmptyClass!,

    # environment.jl functions
    hashEnvironment!,
    initEnvironment,
    isEmpty,
    pad_environment!,

    # FileIO.jl functions
    ageData,
    aliveData,
    createDir,
    dateDir,
    getDirChar,
    getYearlyData,
    getYearlyPop,
    harvestData,
    killedData,
    resultsDir,
    runDir,
    setProjPath,
    simDir,
    simReadme,
    spawnData,

    # mortality.jl
    harvest!,
    kill!,
    killAgeSpecific!,

    # move.jl
    move!,

    # simulate.jl functions
    simulate,

    # spawn.jl
    spawn!,

    # summary.jl
    simSummary,

    # types.jl
    AdultAssumptions,
    AgentAssumptions,
    ClassPopulation,
    EnviroAgent,
    EnvironmentAssumptions,

    # utilities.jl functions
    initPopulationDensity,
    updatePopulationDensity!

    # include types.jl in the module first, types defined in this function are used in other files
    include("types.jl")

    # include any source files with a function used in the module
    include("agents.jl")
    include("environment.jl")
    include("FileIO.jl")
    include("mortality.jl")
    include("move.jl")
    include("simulate.jl")
    include("spawn.jl")
    include("summary.jl")
    include("utilities.jl")
end
