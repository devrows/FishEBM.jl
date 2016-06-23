using FishEBM

function setProjPath()
    """
        INPUT: NA.
        OUTPUT: splitDirPath = current project path.

        Finds the project directory based on the by
        splitting the string of the current directory pathway at
        the first and second intstance of '\\' (in reverse order).
    """
    @assert(OS_NAME == :Windows, "There is currently no functionality for the operating system :$OS_NAME")
    projPath = Base.source_path()
    #add if statement here
    pathEndSearch = rsearch(projPath, "\\")[1]
    endOfDirPath = projPath[pathEndSearch:length(projPath)]
    projPath = split(projPath, endOfDirPath)[1]
    pathEndSearch = rsearch(projPath, "\\")[1]
    endOfDirPath = projPath[pathEndSearch:length(projPath)]
    projPath = split(projPath, endOfDirPath)[1]

    return ascii(projPath)
end


function createDir(path::ASCIIString, exists::Bool)
    """
        INPUT:  path = user specified path
                & exists = True/False.
        OUTPUT: N/A.

        Creates a directory based on the user defined path and has dependency
        on exists. It is reconmended that one passes isdir(path) into exists.
      """
    if exists == true
        print("This directory already exists.\n")
    else
      mkdir(path)
    end
end


function resultsDir(path::ASCIIString)
    """
        INPUT:  path = user specified path.
        OUTPUT: resultsPath = dir. for results folder
                & dirExist = True/False.
    """
    resultsPath = string(path, "\\results")
    dirExist = isdir(resultsPath)

    return (resultsPath,dirExist)
end


function dateDir(path::ASCIIString)
    """
        INPUT:  path = user specified path.
        OUTPUT: datePath = dir. for date folder
                & dirExist = True/False.
    """
    currentDate = string(Dates.today())
    datePath =string(path,string("\\",currentDate))
    dirExist = isdir(datePath)

    return (datePath,dirExist)
end


function runDir(path::ASCIIString)
  """
      INPUT:  path = user specified path.
      OUTPUT: newRunPath = dir. for new run folder,
              currentRunPath = dir. for current run folder,
              & dirExist = True/False.
  """
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


function simReadme(adultAssumpt::AdultAssumptions, agentAssumpt::AgentAssumptions, bump::Vector, effort::Vector, initStock::Vector, carryingCap::Vector, path::ASCIIString, userInput::ASCIIString)
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


function aliveData(popDataFrame::DataFrame, path::ASCIIString)
    """
      INPUT: final_week = final week from simulate's "current_week" IE. the last week of the simulation.
      OUTPUT: simSUMMARY.csv: file containing weekly population levels.
    """

    file = string(path,"\\simSUMMARY.csv")
    writetable(file, popDataFrame)
end


function simSummary(adultAssumpt::AdultAssumptions, agentAssumpt::AgentAssumptions, agentDB::Vector, bump::Vector, effort::Vector, finalWeek::Int64, initStock::Vector, carryingCap::Vector, popDataFrame::DataFrame, userInput::ASCIIString)
    """
        INPUT: See: aliveData() & simReadme().
        OUTPUT: N/A.

        General function for FishEBM.jl to automatically generate summary files per simulation for archiving and analysis.
    """
    simDir()
    path = runDir(dateDir(resultsDir(setProjPath())[1])[1])[2]
    aliveData(popDataFrame, path)
    simReadme(adultAssumpt, agentAssumpt, bump, effort, initStock, carryingCap, path, userInput)
end
