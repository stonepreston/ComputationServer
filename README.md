# ComputationServer

ComputationServer is the backend for the [modellr](https://github.com/stonepreston/modellr) hydraulic modeling application. 

## Installing dependencies

You will need to install Julia. Once installed, you can clone the repository:

```
git clone https://github.com/stonepreston/ComputationServer.git
cd ComputationServer
```

You can install the Julia dependencies with the following commands:

```
julia --project=. # Start the Julia REPL
] # Pressing ] from within the Julia REPL will start the pkg REPL
activate . # Activate the project environment
instantiate # Install dependencies
```

Once the dependencies have been installed you can press `ctrl + c` to exit the Pkg REPL

## Starting the Server
To run the websockets server, use the following command from the Julia REPL after activating the environment and installing the dependencies:

```
include("src/server.jl")
```