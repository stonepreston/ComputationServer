using ModelingToolkit
using DifferentialEquations

function get_node_by_id(model_nodes, node_ID::String)
    for model_node in model_nodes
        if model_node.id == node_ID
            return model_node
        end
    end

    return nothing
end

function get_formatted_name(name)::String
    lowercase(replace(name, " " => "_"))
end


function get_systems_map(model_nodes)::Dict{String, ModelingToolkit.AbstractSystem}

    systems_map::Dict{String, ModelingToolkit.AbstractSystem} = Dict()
    for model_node in model_nodes
        node_data = model_node.data
        model = node_data.model

        model_prototype = ComputationServer.get_model_by_id(model.id)
        formatted_name = get_formatted_name(node_data.label)
        systems_map[model_node.id] = model_prototype.constructor(t, name=Symbol(formatted_name))
    end

    return systems_map
    
end

function find_edges_for_model_node_source(model_node)
end

function find_edges_for_model_node_target(model_node)
end

function is_1_pin_system(system::ModelingToolkit.AbstractSystem)::Bool
    connectors = ComputationServer.get_connections(system)
    return (length(connectors) == 1)
end

function get_source_junction_equations(systems_map::Dict{String, ModelingToolkit.AbstractSystem}, model_nodes, edge_nodes)
    # A source junction is one where one source connects to multiple targets 

    junction_edges = []
    connection_eqs::Vector{Equation} = []
    # Loop over each model node
    for model_node in model_nodes
        # Find any edge nodes where this model node is the source
        source_edges = []
        model_name = model_node.data.label
        println("Searching for edge nodes with source $model_name")
        for edge_node in edge_nodes
            if (edge_node.source == model_node.id)
                source_id = edge_node.source
                println("Found edge node with target $source_id")
                push!(source_edges, edge_node)
            end
        end
        # If we have more than onupe edge here then we have a junction
        if (length(source_edges) > 1)
            println("Found source junction at $model_name")
            # add the source edges to junction_edges
            append!(junction_edges, source_edges)
            source_id::String = source_edges[1].source
            source_system::ModelingToolkit.AbstractSystem = systems_map[source_id]
            target_systems::Vector{ModelingToolkit.AbstractSystem} = []
            for source_edge_node in source_edges
                target_id::String = source_edge_node.target
                target_system::ModelingToolkit.AbstractSystem = systems_map[target_id]
                push!(target_systems, target_system)
            end
            source_pin = nothing
            if (is_1_pin_system(source_system))
                source_pin = source_system.a
            else
                source_pin = source_system.b
            end
            pins::Vector{ModelingToolkit.AbstractSystem} = [source_pin]
            for target_system in target_systems
                push!(pins, target_system.a)
            end

            eqs = connect(pins...)
            for eqn in eqs
                push!(connection_eqs, eqn)
            end
        end
    end

    return (connection_eqs, junction_edges)
end

function get_target_junction_equations(systems_map::Dict{String, ModelingToolkit.AbstractSystem}, model_nodes, edge_nodes)
    # A target junction is one where multiple sources connect to one target 

    junction_edges = []
    connection_eqs::Vector{Equation} = []
    # Loop over each model node
    for model_node in model_nodes
        # Find any edge nodes where this model node is the target
        target_edges = []
        model_name = model_node.data.label
        println("Searching for edge nodes with target $model_name")
        for edge_node in edge_nodes
            if (edge_node.target == model_node.id)
                target_id = edge_node.target
                println("Found edge node with target $target_id")
                push!(target_edges, edge_node)
            end
        end
        # If we have more than one edge here then we have a junction
        if (length(target_edges) > 1)
            println("Found target junction at $model_name")
            # add the target edges to junction_edges
            append!(junction_edges, target_edges)
            target_id::String = target_edges[1].target
            target_system::ModelingToolkit.AbstractSystem = systems_map[target_id]
            source_systems::Vector{ModelingToolkit.AbstractSystem} = []
            for target_edge_node in target_edges
                source_id::String = target_edge_node.source
                source_system::ModelingToolkit.AbstractSystem = systems_map[source_id]
                push!(source_systems, source_system)
            end
            target_pin::ModelingToolkit.AbstractSystem = target_system.a
            pins::Vector{ModelingToolkit.AbstractSystem} = []
            for source_system in source_systems
                push!(pins, source_system.b)
            end
            # Now add the target pin on to the end of the pins array
            push!(pins, target_pin)

            eqs = connect(pins...)
            for eqn in eqs
                push!(connection_eqs, eqn)
            end
        end
    end

    return (connection_eqs, junction_edges)
end

function get_non_junction_equations(systems_map::Dict{String, ModelingToolkit.AbstractSystem}, model_nodes, edge_nodes)::Vector{Equation}
    connection_eqs::Vector{Equation} = []
    for edge_node in edge_nodes
        source_id = edge_node.source
        target_id = edge_node.target

        source_system = systems_map[source_id]
        target_system = systems_map[target_id]

        source_connectors = ComputationServer.get_connections(source_system)
        source_pin = nothing
        target_pin = target_system.a
        # Need to check if we have a 1 pin source or not
        # For normal 2 pin elements pin b on the source connects to pin a on the target
        # However for 1 pin sources pin a on the source connects to pin a on the target
        if length(source_connectors) == 1
            source_pin = source_system.a
        else
            source_pin = source_system.b
        end

        eqs = connect(source_pin, target_pin)
        for eqn in eqs
            push!(connection_eqs, eqn)
        end
    end

    return connection_eqs
end

function remove_junction_edges(edge_nodes, junction_edge_nodes)

    junction_edges_removed = []
    indices_to_remove = []
    for edge_node in junction_edge_nodes
        indices = findall(x -> (x.target == edge_node.target && x.source == edge_node.source), edge_nodes)
        append!(indices_to_remove, indices)
    end

    for i in 1:length(edge_nodes)
        if !(i in indices_to_remove)
            println(edge_nodes[i])
            push!(junction_edges_removed, edge_nodes[i])
        end
    end

    return junction_edges_removed

end

function get_connection_equations(systems_map::Dict{String, ModelingToolkit.AbstractSystem}, model_nodes, edge_nodes)::Vector{Equation}


    source_junction_eqs, source_edges = get_source_junction_equations(systems_map::Dict{String, ModelingToolkit.AbstractSystem}, model_nodes, edge_nodes)
    target_junction_eqs, target_edges = get_target_junction_equations(systems_map::Dict{String, ModelingToolkit.AbstractSystem}, model_nodes, edge_nodes)
    # We need to remove the source and target edges from the edge nodes now:
    source_edges_removed = remove_junction_edges(edge_nodes, source_edges)
    source_and_target_edges_removed = remove_junction_edges(source_edges_removed, target_edges)

    non_junction_eqs = get_non_junction_equations(systems_map::Dict{String, ModelingToolkit.AbstractSystem}, model_nodes, source_and_target_edges_removed)

    # now we combine the 3 sets of equations
    eqs = append!(non_junction_eqs, source_junction_eqs, target_junction_eqs)
    return eqs
end

function build_top_level_system(iv::Num, connections::Vector{Equation}, systems_map::Dict{String, ModelingToolkit.AbstractSystem})::ODESystem
    systems = collect(values(systems_map))
    @named top_level_system = compose(ODESystem(connections, iv), systems)
    return top_level_system
end

function solve_system(system::ODESystem) 
    simplified = structural_simplify(system)
    @show(simplified)
    println("simplified equations")
    println(equations(simplified))
    println("simplified parameters")
    println(parameters(simplified))
    # tspan = (0.0, 0.0)
    # prob = ODEProblem(simplified, [], tspan)
    # sol = solve(prob, Rodas4())
    # return sol
end
