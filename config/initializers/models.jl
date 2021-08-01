using ModelingToolkit: get_connection_type
using Base: String, UInt32
using HydraulicModels
using ModelingToolkit
using StructTypes

include("../../lib/model_types.jl")

@parameters t

static_pipe = Model(1, "Static Pipe", StaticPipe(t; name=:static_pipe))
ideal_pressure_source = Model(2, "Ideal Pressure Source", IdealPressureSource(t; name=:ideal_pressure_source))

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

function build_parameters(system::ModelingToolkit.AbstractSystem)::Vector{Parameter}
    parameterData = []
    for p in parameters(system)
        push!(parameterData, Parameter(string(p), ModelingToolkit.get_defaults(system)[p]))
    end
    return parameterData
end

StructTypes.StructType(::Type{ModelingToolkit.AbstractSystem}) = StructTypes.CustomStruct()
StructTypes.StructType(::Type{ModelingToolkit.ODESystem}) = StructTypes.CustomStruct()

StructTypes.lower(system::ModelingToolkit.AbstractSystem) = System(
    build_parameters(system),
    string.(states(system)),
    string.(equations(system)),
    get_connections(system)
)

build_parameters(static_pipe.system)