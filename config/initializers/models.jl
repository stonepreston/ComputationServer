using ModelingToolkit: get_connection_type
using Base: String, UInt32
using HydraulicModels
using ModelingToolkit
using JSON
@parameters t

struct Model 
    id::UInt32
    name::String
    system::ModelingToolkit.AbstractSystem
end

static_pipe = Model(1, "Static Pipe", StaticPipe(t; name=:static_pipe))
ideal_pressure_source = Model(2, "Ideal Pressure Source", IdealPressureSource(t; name=:ideal_pressure_source))

struct ModelCategory
    category::String
    models::Vector{Model}
end

const categorized_models = ModelCategory[
    ModelCategory("Sources", [ideal_pressure_source]),
    ModelCategory("Pipes", [static_pipe]),
]

function get_connections(system::ModelingToolkit.AbstractSystem)::Vector{String}
    connections::Vector{String} = []
    for subsystem in ModelingToolkit.get_systems(system)
        if isequal(subsystem.connection_type, Pin)
            push!(connections, string(subsystem.name))
        end
    end
    return connections
end

function get_model_by_id(id::UInt32)
    for category in categorized_models
        for model in category.models
            if model.id == id
                return model
            end
        end
    end

    return nothing
end

struct System 
    parameters::Vector{String}
    states::Vector{String}
    equations::Vector{String}
    connections::Vector{String}
end

JSON.lower(system::ModelingToolkit.AbstractSystem) = System(
    string.(parameters(system)),
    string.(states(system)),
    string.(equations(system)),
    get_connections(system)
)

