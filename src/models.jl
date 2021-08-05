using ModelingToolkit: get_connection_type
using Base: String, UInt32
using HydraulicModels
using ModelingToolkit
using StructTypes

include("./model_types.jl")

@parameters t

static_pipe = Model(1, "Static Pipe", StaticPipe(t; name=:static_pipe), StaticPipe)
ideal_pressure_source = Model(2, "Ideal Pressure Source", IdealPressureSource(t; name=:ideal_pressure_source), IdealPressureSource)

categorized_models = ModelCategory[
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

function get_model_by_id(id::UInt64)
    for category in categorized_models
        for model in category.models
            if model.id == id
                return model
            end
        end
    end

    return nothing
end

function get_model_by_id(id::Int64)
    get_model_by_id(convert(UInt64, id))
end

function build_parameters(system::ModelingToolkit.AbstractSystem)::Vector{Parameter}
    parameterData = []
    for p in parameters(system)
        push!(parameterData, Parameter(string(p), ModelingToolkit.get_defaults(system)[p]))
    end
    return parameterData
end

