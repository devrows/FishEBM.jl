using FishEBM

function setProjPath()
    """
        INPUT: NA.
        OUTPUT: splitDirPath = current project path.

        Finds the project directory based on the by
        splitting the string of the current directory pathway at
        the first and second intstance of '\\' (in reverse order).
    """

    projPath = Base.source_path()
    pathEndSearch = rsearch(projPath, "\\")[1]
    endOfDirPath = projPath[pathEndSearch:length(projPath)]
    projPath = split(projPath, endOfDirPath)[1]
    pathEndSearch = rsearch(projPath, "\\")[1]
    endOfDirPath = projPath[pathEndSearch:length(projPath)]
    projPath = split(projPath, endOfDirPath)[1]

    return ascii(projPath)
end


function createDir(path::ASCIIString, exists::Bool)

    if exists == true
        print("This directory already exists.\n")
    else
      mkdir(path)
    end
end


function resultsDir(path::ASCIIString)
    resultsPath = string(path, "\\results")
    dirExist = isdir(resultsPath)

    return (resultsPath,dirExist)
end


function dateDir(path::ASCIIString)
    currentDate = string(Dates.today())
    datePath =string(path,string("\\",currentDate))
    dirExist = isdir(datePath)

    return (datePath,dirExist)
end


function runDir(path::ASCIIString)
  dirCounter = 0
  stopCriteria = 0

  while (stopCriteria == 0)
      newRunPath = string(path,string("\\run_", dirCounter))
      dirExist = isdir(newRunPath)

      if dirExist == false
          stopCriteria = 1
      elseif dirExist == true
          dirCounter = dirCounter + 1
      end
  end

  if dirCounter == 0
      currentRunPath = string(path,string("\\run_", dirCounter))
  else
      currentRunPath = string(path,string("\\run_", dirCounter-1))
  end

  newRunPath = string(path,string("\\run_", dirCounter))
  dirExist = isdir(newRunPath)

  return (newRunPath, currentRunPath, dirExist)
end


function simDir()
    """
        INPUT: none.
        OUTPUT: none.

        Creates the newest directory for the current simulation.
    """

    path = setProjPath()
    results = resultsDir(path)
    date = dateDir(results[1])
    run = runDir(date[1])

    createDir(results[1],results[2])
    createDir(date[1],date[2])
    createDir(run[1],run[3])
end


function simReadme(adultAssumpt::AdultAssumptions, agentAssumpt::AgentAssumptions, bump::Array{Int64,1}, effort::Array{Int64,1}, initStock::Array{Int64,1}, carryingCap::Int64, path::ASCIIString, userInput::ASCIIString)
    """
        INPUT: runDir, userInput, k, effort, bump, initStock, adultAssumpt, agentAssumpt.
        OUTPUT: simREADME.txt

        Function creats a formatted textfile containing information particular to a simulation's run.
        The file saves in the same directory as the current date's run number. For descriptions
        of the INPUT's please refer to types.jl. Note, runDir and userInput are user given
        PATH and description respectively.
    """

    file_name = string(path,"\\simREADME.txt")
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


function aliveData(agentAssumpt::AgentAssumptions, agentDB::Vector, finalWeek::Int64, path::ASCIIString)
    """
      INPUT: final_week = final week from simulate's "current_week" IE. the last week of the simulation.
      OUTPUT: simSUMMARY.csv: file containing weekly population levels.
    """
    stagePopulation = [0,0,0,0]
    popDataFrame = DataFrame(Week = 0, Stage1 = stagePopulation[1], Stage2 = stagePopulation[2], Stage3 = stagePopulation[3],Stage4 = stagePopulation[4], Total = sum(stagePopulation))

    for i = 1:finalWeek
      for j = 1:4
        stagePopulation[j] = getStagePopulation(j, finalWeek, agentDB, agentAssumpt)
      end
      push!(popDataFrame,(i,stagePopulation[1],stagePopulation[2],stagePopulation[3],stagePopulation[4],sum(stagePopulation)))
    end

    file = string(path,"\\simSUMMARY.csv")
    writetable(file, popDataFrame)
end


function simSummary(adultAssumpt::AdultAssumptions, agentAssumpt::AgentAssumptions, agentDB::Vector, bump::Array{Int64,1}, effort::Array{Int64,1}, finalWeek::Int64, initStock::Array{Int64,1}, carryingCap::Int64, userInput::ASCIIString)
    simDir()
    path = runDir(dateDir(resultsDir(setProjPath())[1])[1])[2]
    aliveData(agentAssumpt, agentDB, finalWeek, path)
    simReadme(adultAssumpt, agentAssumpt, bump, effort, initStock, carryingCap, path, userInput)
end
