module ModelTypes

using Base: String, UInt32
using ModelingToolkit

struct Model 
    id::UInt32
    name::String
    system::ModelingToolkit.AbstractSystem
end

struct ModelCategory
    category::String
    models::Vector{Model}
end

struct Parameter
    name::String
    value::Number
end

struct System 
    parameters::Vector{Parameter}
    states::Vector{String}
    equations::Vector{String}
    connections::Vector{String}
end

end