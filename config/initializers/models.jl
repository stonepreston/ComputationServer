using ModelingToolkit: get_connection_type
using Base: String
using HydraulicModels
using ModelingToolkit

@parameters t

const static_pipe_key = "Static Pipe"
const ideal_pressure_source_key  = "Ideal Pressure Source"

# struct Model 
#     id::UInt32
#     name::String
#     constructor::Function
# end


const models = Dict{String, Function}(
    static_pipe_key => StaticPipe,
    ideal_pressure_source_key => IdealPressureSource
)

function get_model_keys()
    return sort(collect(keys(models)), by=x->x[1])
end

struct ModelCategory 
    category_key::String
    model_keys::Vector{String}
end

const model_categories = ModelCategory[
    ModelCategory("Pipes", [static_pipe_key]),
    ModelCategory("Sources", [ideal_pressure_source_key])
]

function get_connections(system::ModelingToolkit.AbstractSystem)
    connections::Vector{String} = []
    for subsystem in ModelingToolkit.get_systems(system)
        if isequal(subsystem.connection_type, Pin)
            push!(connections, string(subsystem.name))
        end
    end
    return connections
end

function get_connections_for_model_key(key::String)
    model_constructor::Function = models[key]
    get_connections(model_constructor(t; name=Symbol(key)))
end
