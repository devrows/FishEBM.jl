# Load required packages
using FishEBM, DataFrames

#fill params
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



#a_db = AgentDB(e_a)
#e_a = generateEnvironment(spawnPath, habitatPath, riskPath)



# Specify agent assumptions:
# * a_a.naturalmortality =  Weekly natural mortality rate (by habitat type in the rows, and stage in the columns)
# * a_a.extramortality = Weekly risk mortality (by stage)
# * a_a.growth = Stage length (in weeks)
# * a_a.movement = Movement weight matrices
# * a_a.autonomy =  Movement autonomy

a_a = AgentAssumptions([[0.80 0.095 0.09 0.05]
                        [0.10 0.095 0.09 0.10]
                        [0.80 0.095 0.09 0.20]
                        [0.80 0.80 0.09 0.30]
                        [0.80 0.80 0.80 0.40]
                        [0.80 0.80 0.80 0.50]],
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
                       [0., 0.5, 0.75, 0.5])




#generate agent db and hash environemt for Testing
a_db = AgentDB(enviro_a)
hashEnvironment!(a_db, enviro_a)

#inject agents into agent db for testing nonempty agent db
addingStock = [5000, 10000, 15000, 20000]
for i = 1:4
  injectAgents!(a_db, enviro_a.spawningHash, addingStock[5-i], -a_a.growth[((7-i)%4)+1])
end

# Additional values, used in simSummary
# *k = carrying capacity.
# *effort = fishing effort.
# *bump = stock pop. bump (might be removed in time.)
k = 1
effort = [0]
bump = [100000]
description = "Test description for simulation simREADME file."
finalWeek = 5

# Generates: /results/<date>/run_<i>/<simREADME.txt, simSUMMARY.csv>, as a warning, these are non-empty files.
@time simSummary(adult_a, a_a, a_db, bump, effort, finalWeek, addingStock, k, description)
