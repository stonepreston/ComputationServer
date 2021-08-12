
using ModelingToolkit
using StructTypes

struct Parameter
    name::String
    value::Number
end
StructTypes.StructType(::Type{Parameter}) = StructTypes.Struct()

struct Argument
    name::String
    value::Float64
end
StructTypes.StructType(::Type{Argument}) = StructTypes.Struct()

struct System 
    parameters::Vector{Parameter}
    arguments::Vector{Argument}
    states::Vector{String}
    equations::Vector{String}
    connections::Vector{String}
end
StructTypes.StructType(::Type{System}) = StructTypes.Struct()

struct Model 
    id::UInt64
    name::String
    system::ModelingToolkit.AbstractSystem
    constructor::Function
end
StructTypes.StructType(::Type{Model}) = StructTypes.Struct()

struct ModelCategory
    category::String
    models::Vector{Model}
end
StructTypes.StructType(::Type{ModelCategory}) = StructTypes.Struct()

struct SerializedModel 
    id::UInt64
    name::String
    system::ModelingToolkit.AbstractSystem
    constructor::String
end
StructTypes.StructType(::Type{SerializedModel}) = StructTypes.Struct()

StructTypes.StructType(::Type{T}) where {T <: ModelingToolkit.AbstractSystem} = StructTypes.CustomStruct()
StructTypes.StructType(::Type{Model}) = StructTypes.CustomStruct()

StructTypes.lower(model::Model) = SerializedModel(
    model.id,
    model.name,
    model.system,
    string(nameof(model.constructor))
)

StructTypes.lower(system::ModelingToolkit.AbstractSystem) = System(
    build_parameters(system),
    build_arguments(system),
    string.(states(system)),
    string.(equations(system)),
    get_connections(system)
)



