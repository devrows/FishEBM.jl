"""
  Package: FishEBM
  File: FishEBM.jl
  Justin Angevaare, Devin Rose
  Module definition for an agent-based model
  May 2015
"""

module FishEBM

  #Packages used by this package
  using Distributions, ProgressMeter

  export
    # agent_stock_interaction.jl functions

    # agents.jl functions
    AgentDB,
    findCurrentStage,
    injectAgents!,
    removeEmptyClass!,

    # environment.jl functions
    isEmpty,
    hashEnvironment!,
    initEnvironment,
    pad_environment!,

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
    include("agent_stock_interaction.jl")
    include("agents.jl")
    include("environment.jl")
    include("simulate.jl")
    include("simulationResults.jl")
    include("stock.jl")
    include("utilities.jl")
end
