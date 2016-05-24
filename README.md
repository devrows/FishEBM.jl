# FishEBM.jl
This project is a continuation of: [FishABM.jl](https://github.com/devrows/FishABM.jl/)

A new repository was created for this project because the model is no longer a traditional agent based model. The model uses a new approach for simulating the interaction between individual agents and the surrounding environment and data storage during the simulation.

This package contains functions to simulate the life cycle dynamics of managed fisheries. A fish population is divided into two components: adults and pre-recruits.

Adults have age-specific survivorship, are harvested with age specific catchability, and spawn with age specific sexual maturity and fecundity. Agents graduate between several life stages, move, and face multiple forms of stage and location specific mortality. The the model is a detailed and computationally intensive agent based model that does not track each individual agent, instead the environment is monitored while agents move throughout the chosen environment. This simulation tool is well suited for investigation of spatial risks in managed populations, where population level impacts may only be observable through changes in harvest.

To download and use package in Julia:

`Pkg.clone("https://github.com/devrows/FishEBM.jl.git")`

`using FishEBM`
