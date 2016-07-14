#=
  Package: FishEBM
  File: FileIO.jl
  Devin Rose
  Functions for summarizing the results of a simulation
  Created: June 2016
=#


"""
  INPUT: ageDataFrame = DataFrame of yearly adult age-specific population.
  OUTPUT: ageSUMMARY.csv: file containing yearly age-specific population levels.

  Last update: June 2016
"""
function ageData(adf::DataFrame, path::ASCIIString)
  separateDirChar = getDirChar()

  file = string(path,"$(separateDirChar)ageSpecificSUMMARY.csv")
  f = open(file, "w")
  adfOut = convert(Array, adf)
  writedlm(f, names(adf)', " ,")
  writedlm(f, adfOut,  " ,")
  close(f)
end


"""
  INPUT: popDataFrame = DataFrame of weekly stage population.
  OUTPUT: simSUMMARY.csv: file containing weekly population levels.

  Last update: June 2016
"""
function aliveData(popDataFrame::DataFrame, path::ASCIIString)
  separateDirChar = getDirChar()

  file = string(path,"$(separateDirChar)stageSUMMARY.csv")
  f = open(file, "w")
  popDataOutput = convert(Array, popDataFrame)
  writedlm(f, names(popDataFrame)', " ,")
  writedlm(f, popDataOutput,  " ,")
  close(f)
end


"""
  Description: Creates a directory based on the user defined path and has
    dependency on exists. It is reconmended that one passes isdir(path) into
    exists.

  Returns: N/A

  Last update: June 2016
"""
function createDir(path::ASCIIString, exists::Bool)
  if exists == true
    print("A directory already exists in the path $path.\n")
  else
    mkdir(path)
  end
end


"""
  INPUT:  path = user specified path.
  OUTPUT: datePath = dir. for date folder
          & dirExist = True/False.
"""
function dateDir(path::ASCIIString)
  currentDate = string(Dates.today())
  datePath = string(path,string(getDirChar(), currentDate))
  dirExist = isdir(datePath)

  return (datePath,dirExist)
end


"""
  Description: Finds the character used to separate the path based on current OS

  Returns: ASCIIString

  Last update: July 2016
"""
function getDirChar()
  @assert(OS_NAME == :Windows || OS_NAME == :Darwin, "There is currently no
    functionality for the operating system :$OS_NAME, now aborting.")
  if OS_NAME == :Windows
    return "\\"
  elseif OS_NAME == :Darwin
    return "/"
  elseif OS_NAME == :Linux
    return "/"
  end
end


"""
  INPUT: hdf = DataFrame of weekly age-specific harvest levels and total harvest.
  OUTPUT: harvestSUMMARY.csv: file containing weekly harvest levels.

  Last update: June 2016
"""
function harvestData(hdf::DataFrame, path::ASCIIString)
  file = string(path,"$(getDirChar())harvestSUMMARY.csv")
  writetable(file, hdf)
end


"""
  INPUT: kdf = DataFrame of weekly killed data by natural and extra mortality.
  OUTPUT: killedSUMMARY.csv: file containing weekly mortality levels.

  Last update: June 2016
"""
function killedData(kdf::DataFrame, path::ASCIIString)
  file = string(path,"$(getDirChar())killedSUMMARY.csv")
  f = open(file, "w")

  #Sum natural, extra, and Compensatory mortalities before outputting to .csv
  for i = 1:size(kdf)[1]
    totalKill = 0
    for j = 2:4
      totalKill += kdf[i,j]
    end #for j
    kdf[i,5] = totalKill
  end #for i

  kdfOut = convert(Array, kdf)
  writedlm(f, names(kdf)', " ,")
  writedlm(f, kdfOut,  " ,")
  close(f)
end


"""
  INPUT:  path = user specified path.

  OUTPUT: resultsPath = dir. for results folder
    & dirExist = True/False.
"""
function resultsDir(path::ASCIIString)
    resultsPath = string(path, "$(getDirChar())results")
    dirExist = isdir(resultsPath)

    return (resultsPath,dirExist)
end


"""
  INPUT:  path = user specified path.
  OUTPUT: newRunPath = dir. for new run folder,
          currentRunPath = dir. for current run folder,
          & dirExist = True/False.
"""
function runDir(path::ASCIIString)
  dirCounter = 0
  stopCriteria = 0

  while (stopCriteria == 0)
    newRunPath = string(path,string("$(getDirChar())run_", dirCounter))
    dirExist = isdir(newRunPath)

    if dirExist == false
      stopCriteria = 1
    elseif dirExist == true
      dirCounter = dirCounter + 1
    end
  end

  if dirCounter == 0
    currentRunPath = string(path,string("$(getDirChar())run_", dirCounter))
  else
    currentRunPath = string(path,string("$(getDirChar())run_", dirCounter-1))
  end

  newRunPath = string(path,string("$(getDirChar())run_", dirCounter))
  dirExist = isdir(newRunPath)

  return (newRunPath, currentRunPath, dirExist)
end


"""
    Description: Finds the project directory based on the by splitting the
      string of the current directory pathway at the first and second intstance
      of '\\' (in reverse order).

    Returns: ASCIIString

    Last update: June 2016
"""
function setProjPath()
  projPath = Base.source_path() #find current project path
  separateDirChar = getDirChar()
  pathEndSearch = rsearch(projPath, separateDirChar)[1]
  endOfDirPath = projPath[pathEndSearch:length(projPath)]
  projPath = split(projPath, endOfDirPath)[1]
  pathEndSearch = rsearch(projPath, separateDirChar)[1]
  endOfDirPath = projPath[pathEndSearch:length(projPath)]
  projPath = string(split(projPath, endOfDirPath)[1], "$(getDirChar())simulations")

  return ascii(projPath) #returns the path to FishEBM.jl
end


"""
  Description: Creates the newest directory for the current simulation.

  Returns: N/A

  Last update: June 2016
"""
function simDir()

  path = setProjPath()
  results = resultsDir(path)
  date = dateDir(results[1])
  run = runDir(date[1])

  createDir(results[1],results[2])
  createDir(date[1],date[2])
  createDir(run[1],run[3])
end


"""
  INPUT: runDir, userInput, k, effort, bump, initStock, adultAssumpt,
    agentAssumpt.
  OUTPUT: simREADME.txt

    Description :Function creats a formatted textfile containing information
      particular to a simulation's run. The file saves in the same directory as
      the current date's run number. For descriptions of the INPUT's please
      refer to types.jl. Note, runDir and userInput are user given PATH and
      description respectively.

  Last update: June 2016
"""
function simReadme(adultAssumpt::AdultAssumptions, agentAssumpt::AgentAssumptions, bump::Vector, effort::Vector, initStock::Vector, carryingCap::Vector, path::ASCIIString, userInput::ASCIIString)

  file_name = string(path,"$(getDirChar())simREADME.txt")
  output_file = open(file_name, "w")

  write(output_file,"-------------------------\n")
  description_string = "Simulation Description: \n-------------------------\n"
  write(output_file, description_string)
  write(output_file, userInput)
  write(output_file, "\n")

  write(output_file,"\n-------------------------\n")
  genAssumpt_string = "General Assumptions: \n-------------------------\n"
  write(output_file, genAssumpt_string)

  carryingCap_string = string("Carrying capacity: ",carryingCap,"\n")
  write(output_file, carryingCap_string)

  effort_string = "Effort vector: "
  write(output_file, effort_string)
  show(output_file, effort)
  write(output_file, "\n")

  bump_string = "Bump vector: "
  write(output_file, bump_string)
  show(output_file, bump)
  write(output_file, "\n")

  initStock_string = "Initial stock values are: "
  write(output_file,initStock_string)
  show(output_file, initStock)
  write(output_file, "\n")

  write(output_file,"\n-------------------------\n")
  adultAssumpt_string = "Adult Assumptions: \n-------------------------\n"
  write(output_file,adultAssumpt_string)

  write(output_file,"Natural Mortality vector: ")
  show(output_file,adultAssumpt.naturalmortality)
  write(output_file, "\n")

  halfmature_string = string("Age at half maturity: ",adultAssumpt.halfmature,"\n")
  write(output_file,halfmature_string)

  fc_string = string("Fecundity compensation value: ",adultAssumpt.fecunditycompensation,"\n")
  write(output_file,fc_string)

  matC_string = string("Maturity compensation value: ",adultAssumpt.maturitycompensation,"\n")
  write(output_file,matC_string)

  morC_string = string("Mortality compensation value: ",adultAssumpt.mortalitycompensation,"\n")
  write(output_file,morC_string)

  catch_string = "Catchability: "
  write(output_file, catch_string)
  show(output_file,adultAssumpt.catchability)
  write(output_file, "\n")

  write(output_file,"\n-------------------------\n")
  agentAssumpt_string = "Agent Assumptions: \n-------------------------\n"
  write(output_file,agentAssumpt_string)

  natMor_string = "Natural mortality array: \n"
  write(output_file, natMor_string)
  show(output_file, agentAssumpt.naturalmortality)
  write(output_file, "\n")

  extraMor_string = "Extra mortality vector: "
  write(output_file, extraMor_string)
  show(output_file, agentAssumpt.extramortality)
  write(output_file, "\n")

  growth_string = "Growth vector: "
  write(output_file, growth_string)
  show(output_file, agentAssumpt.growth)
  write(output_file, "\n")

  move_string = "Movement matricies: \n"
  write(output_file, move_string)
  show(output_file, agentAssumpt.movement)
  write(output_file, "\n")

  auto_string = "Autonomy vector: "
  write(output_file, auto_string)
  show(output_file, agentAssumpt.autonomy)

  close(output_file)
end


"""
  INPUT: See: aliveData() & simReadme().

  Description: General function for FishEBM.jl to automatically generate summary
    files per simulation for archiving and analysis.

  Returns: N/A.

  Last update: June 2016
"""
function simSummary(adultAssumpt::AdultAssumptions,
  agentAssumpt::AgentAssumptions, agentDB::Vector, bump::Vector, effort::Vector,
  finalWeek::Int64, initStock::Vector, carryingCap::Vector,
  popDataFrame::DataFrame, ageDataFrame::DataFrame, harvestDataFrame::DataFrame,
  spawnDataFrame::DataFrame, killedDataFrame::DataFrame, userInput::ASCIIString)

  simDir()
  path = runDir(dateDir(resultsDir(setProjPath())[1])[1])[2]
  aliveData(popDataFrame, path)
  ageData(ageDataFrame, path)
  harvestData(harvestDataFrame, path)
  spawnData(spawnDataFrame, path)
  killedData(killedDataFrame, path)
  simReadme(adultAssumpt, agentAssumpt, bump, effort, initStock, carryingCap, path, userInput)
end


"""
  INPUT: sdf = DataFrame of weekly age-specific spawn levels and total spawn size.
  OUTPUT: spawnSUMMARY.csv: file containing weekly spawn levels.

  Last update: June 2016
"""
function spawnData(sdf::DataFrame, path::ASCIIString)
  file = string(path,"$(getDirChar())spawnSUMMARY.csv")
  f = open(file, "w")
  sdfOut = convert(Array, sdf)
  writedlm(f, names(sdf)', " ,")
  writedlm(f, sdfOut,  " ,")
  close(f)
end
