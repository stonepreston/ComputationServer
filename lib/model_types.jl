using Base: String, UInt32
using ModelingToolkit
using StructTypes

struct Model 
    id::UInt32
    name::String
    system::ModelingToolkit.AbstractSystem
end
StructTypes.StructType(::Type{Model}) = StructTypes.Struct()

struct ModelCategory
    category::String
    models::Vector{Model}
end
StructTypes.StructType(::Type{ModelCategory}) = StructTypes.Struct()

struct Parameter
    name::String
    value::Number
end
StructTypes.StructType(::Type{Parameter}) = StructTypes.Struct()

struct System 
    parameters::Vector{Parameter}
    states::Vector{String}
    equations::Vector{String}
    connections::Vector{String}
end
StructTypes.StructType(::Type{System}) = StructTypes.Struct()

