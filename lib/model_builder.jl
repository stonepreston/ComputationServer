using ModelingToolkit

function get_systems(model_nodes)::Dict{String, ModelingToolkit.AbstractSystem}

    systems::Dict{String, ModelingToolkit.AbstractSystem} = Dict()
    for model_node in model_nodes
        node_data = model_node.data
        model = node_data.model

        model_prototype = ComputationServer.get_model_by_id(model.id)
        formatted_name = get_formatted_name(node_data.label)
        systems[formatted_name] = model_prototype.constructor(t, name=Symbol(formatted_name))
    end

    return systems
    
end

function get_formatted_name(name)
    lowercase(replace(name, " " => "_"))
end