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

    return projPath
end


function createResDir(projPath::SubString)
    """
        INPUT: projPath = current project path.
        OUTPUT: resultsDirPath = location of results directory.

        Creates a results directory the the location of INPUT. Defensively
        checks if a results directory already exists. Might be wise to just
        skip the check and produce results. That is, people will have a results
        directory, a check after will be kinda redundant, maybe...
    """

    resultsDirPath = string(projPath, "\\results")
    dirResultsExist = isdir(resultsDirPath)

    if dirResultsExist == false
        mkdir(resultsDirPath)
        print("Creating a results directory.\n")
    elseif dirResultsExist == true
        print("Results directory already exists\n")
    end

    return resultsDirPath
end


function createDateDir(resultsDirPath::ASCIIString)
    """
        INPUT: resultsDirPath = location of results directory.
        OUTPUT: fullDir = location of the current dates directory.

        Creates a new directory for a set of results (based on input and date).
        Defensively checks to see if a current directory exists for the same date.
    """
    currentDate = string(Dates.today())
    resultsDirName = string("\\",currentDate)
    fullDir = string(resultsDirPath, resultsDirName)
    dirExist = isdir(fullDir)

    if dirExist == true
        print("A directory for: ",currentDate," already exists.\n")
    elseif dirExist == false
        mkdir(fullDir)
        print("Creating a directory specific to: ", currentDate,"\n")
    end

    return fullDir
end


function createRunDir(runDir::ASCIIString)
    """
        INPUT: runDir = location of the current run directory.
        OUTPUT: none.

        Creates a RUN directory based on its INPUT.
    """

    print("Now printing README to ", runDir,"\n")
    mkdir(runDir)
end


function runDirCheck(fullDir::ASCIIString)
    """
        INPUT: fullDir = user specified directory PATH.
        OUTPUT: String containing the PATH for a currently
                non-existent RUN directory.

        Checks if a run directory already exist (reliant on INPUT).
    """

    dirCounter = 0
    stopCriteria = 0

    while (stopCriteria == 0)
        runDirSub = string("\\run_", dirCounter)
        dirExist = isdir(string(fullDir, runDirSub))

        if dirExist == false
            runDir = string(fullDir, runDirSub)
            return string(runDir)
            stopCriteria = 1
        end
        dirCounter = dirCounter + 1
    end
end


function standardReport()
    """
        INPUT: none.
        OUTPUT: none.

        Runs the nested call back function for standard result reporting.
        IE. assuming there is no custom input from the user.
    """

    runDir  = runDirCheck(createDateDir(createResDir(setProjPath())))
    createRunDir(runDir)

    return string(runDir)
end


function createReadme(runDir::ASCIIString, userInput::ASCIIString, k::Int64, effort::Array{Int64,1}, bump::Array{Int64,1}, initStock::Array{Int64,1}, adultAssumpt::AdultAssumptions,
  agentAssumpt::AgentAssumptions)
    """
        INPUT: runDir, userInput, k, effort, bump, initStock, adultAssumpt, agentAssumpt.
        OUTPUT: SIMREADME.txt

        Function creats a formatted textfile containing information particular to a simulation's run.
        The file saves in the same directory as the current date's run number. For descriptions
        of the INPUT's please refer to types.jl. Note, runDir and userInput are user given
        PATH and description respectively.
    """

    file_name = string(runDir,"\\test.txt")
    output_file = open(file_name, "w")

    write(output_file,"-------------------------\n")
    description_string = "Simulation Description: \n-------------------------\n"
    write(output_file, description_string)
    write(output_file, userInput)
    write(output_file, "\n")

    write(output_file,"\n-------------------------\n")
    genAssumpt_string = "General Assumptions: \n-------------------------\n"
    write(output_file, genAssumpt_string)

    carryingCap_string = string("Carrying capacity: ",k,"\n")
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


function summary(a_db::Vector)

end
