# Load required packages
using FishEBM, Distributions


# Specify stock assumptions:
# * s_a.naturalmortality = Age specific mortality
# * s_a.halfmature = Age at 50% maturity
# * s_a.broodsize = Age specific fecundity
# * s_a.fecunditycompensation = Compensatory strength - fecundity
# * s_a.maturitycompensation = Compensatory strength - age at 50% maturity
# * s_a.mortalitycompensation = Compensatory strength - adult natural mortality
# * s_a.catchability = Age specific catchability
adult_a = AdultAssumptions([0.35, 0.40, 0.45, 0.50, 0.55, 0.60, 0.65],
                       5,
                       [2500, 7500, 15000, 20000, 22500, 27500, 32500],
                       2,
                       0.25,
                       1,
                       [0.00001, 0.00002, 0.000025, 0.000025, 0.000025, 0.000025, 0.000025])


# Specify environment assumptions:
# * e_a.spawning = Spawning areas
# * e_a.habitat = Habitat types
# * e_a.risk = Risk areas
spawnPath = string(split(Base.source_path(), "FishEBM.jl")[1], "FishEBM.jl/maps/LakeHuron_1km_spawning.csv")
habitatPath = string(split(Base.source_path(), "FishEBM.jl")[1], "FishEBM.jl/maps/LakeHuron_1km_habitat.csv")
riskPath = string(split(Base.source_path(), "FishEBM.jl")[1], "FishEBM.jl/maps/LakeHuron_1km_risk.csv")

enviro_a = initEnvironment(spawnPath, habitatPath, riskPath)


# Specify agent assumptions:
# * a_a.naturalmortality =  Weekly natural mortality rate (by habitat type in the rows, and stage in the columns)
# * a_a.extramortality = Weekly risk mortality (by stage)
# * a_a.growth = Stage length (in weeks)
# * a_a.movement = Movement weight matrices
# * a_a.autonomy =  Movement autonomy

agent_a = AgentAssumptions([[0.15 0.10 0.05 0.002]
                        [0.05 0.04 0.02 0.001]
                        [0.40 0.20 0.10 0.004]
                        [0.60 0.30 0.15 0.006]
                        [0.80 0.40 0.20 0.008]
                        [0.90 0.50 0.25 0.03]],
                       [0.0, 0.0, 0.0, 0.0],
                       [19, 52, 104, 0],
                       Array[[[0. 0. 0.]
                              [0. 1. 0.]
                              [0. 0. 0.]], [[1. 2. 1.]
                                            [1. 2. 1.]
                                            [1. 1. 1.]], [[1. 2. 1.]
                                                          [1. 1. 1.]
                                                          [1. 1. 1.]], [[1. 2. 1.]
                                                                        [1. 1. 1.]
                                                                        [1. 1. 1.]]],
                       [0., 0.25, 0.5, 0.75])


# Begin life cycle simulation, specifying:
# * Year specific carrying capacity (vector length determines simulation length)
# * Annual fishing effort
# * Population bump


k = rand(Normal(500000, 50000), 20)
effortVar = [0]
bumpVar = [100000]
initialStock = [5000, 10000, 12500, 15000]


adb = simulate(k, effortVar, bumpVar, initialStock, enviro_a, adult_a, agent_a)
