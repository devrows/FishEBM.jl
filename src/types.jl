#=
  Package: FishEBM
  File: types.jl
  Justin Angevaare, Devin Rose
  Type definitions for the structured stock-level and agent-level model components
  Created: May 2015
=#


"""
  naturalmortality = Age specific survivorship (survivorship at carrying
    capacity if density depedence occurs)
  halfmature = Age at 50% mature (Binomial cdf assumed)
  broodsize = Age specific fecundity (i.e. mean quantity of eggs each spawning
    female will produce)
  fecunditycompensation = compensatory strength for changes in fecundity.
    Compensatory strength is a divisor of K which will result in a 68% change in
    fecundity - smaller values indicate lower compensation strength.
    Compensation function based on Normal CDF. Use NaN if compensation is
    assumed to not occur.
  maturitycompensation = compensatory strength for changes in age of sexual
    maturity. Compensatory strength is a divisor of K which will result in a 68%
    change in age of sexual maturity - smaller values indicate lower
    compensation strength. Compensation function based on Normal CDF. Use NaN if
    compensation is assumed to not occur.
  mortalitycompensation = compensatory strength for changes in age of sexual
    maturity. Compensatory strength is a divisor of K which will result in a 68%
    change in natural mortality - smaller values indicate lower compensation
    strength. Compensation function based on Normal CDF. Use NaN if compensation
    is assumed to not occur.

    Last Update: March 2016
"""
type AdultAssumptions
  naturalmortality::Vector
  halfmature::Float64
  broodsize::Vector
  fecunditycompensation::Float64
  maturitycompensation::Float64
  mortalitycompensation::Float64
  catchability::Vector

  AdultAssumptions() = new()
  AdultAssumptions(naturalmortality, halfmature, broodsize, fecunditycompensation, maturitycompensation, mortalitycompensation, catchability) =
    new(naturalmortality, halfmature, broodsize, fecunditycompensation, maturitycompensation, mortalitycompensation, catchability)
end


"""
  Description: Assumptions regarding mortality, movement, and growth of agents.

  Last Update: April 2016
"""
type AgentAssumptions
  naturalmortality::Array
  extramortality::Vector
  growth::Vector
  movement::Array
  autonomy::Vector

  AgentAssumptions() = new()
  AgentAssumptions(naturalmortality, extramortality, growth, movement, autonomy) =
    new(naturalmortality, extramortality, growth, movement, autonomy)
end


"""
  Description: This "Environment agent" is used to track fish population
    dynamics during a simulation.

  Last Update: June 2016
"""
type EnviroAgent
  locationID::Int64 #locationID corresponds to the ID in the habitat array

  alive::Vector
  killedNatural::Vector
  killedExtra::Vector
  harvest::Int64
  weekNum::Vector

  EnviroAgent(locationID) = new(locationID, [0], [0,0,0,0], [0,0,0,0], 0, [0])
end


"""
  Description: A specialized type which contains layers of information to
    indicate spawning area, habitat type, and additional risks.

  Precondition: Location id should be specified as NaN when a valid location
    does not exist.

  Last Update: March 2016
"""
type EnvironmentAssumptions
  spawning::Array
  spawningHash::Vector
  habitat::Array
  risk::Vector
  riskHash::Vector
  harvest::DataFrame

  EnvironmentAssumptions() = new()

  EnvironmentAssumptions(spawning, spawningHash, habitat, risk, riskHash, harvest) =
  new(spawning, spawningHash, habitat, risk, riskHash, harvest)
end
