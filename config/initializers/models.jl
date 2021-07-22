using Base: String
using HydraulicModels
using ModelingToolkit

@parameters t

const static_pipe_key = "Static Pipe"
const ideal_pressure_source_key  = "Ideal Pressure Source"

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
