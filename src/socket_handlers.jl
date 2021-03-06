using HTTP: WebSockets
using JSON3
using HTTP
using Match
using DiffEqFlux
include("./model_builder.jl")

clients = Dict{String, HTTP.WebSockets.WebSocket}()

function handleMessage(ws::HTTP.WebSockets.WebSocket, message::String) 

    message = JSON3.read(message)
    id = message["id"]
    event = message["event"]
    data = message["data"]
    println("Client: $id sent event $event")
    println("**********************************************************************")

    @match event begin
        "connect" => on_connect(ws, id)
        "disconnect" => on_disconnect(ws, id)
        "build_model" => on_build_model(ws, id, data)
        "estimate_parameters" => on_estimate_parameters(ws, id, data)
    end

end

function on_connect(ws::HTTP.WebSockets.WebSocket, id::String)
    println("connect event received from client $id")
    clients[id] = ws
end

function on_disconnect(ws::HTTP.WebSockets.WebSocket, id::String)
    println("disconnect event received from client $id")
    delete!(clients, id)
    WebSockets.close(ws)
end

function on_build_model(ws::HTTP.WebSockets.WebSocket, id, data) 
    println("build_model event received from client $id")
    edge_modes = data.edgeNodes
    model_nodes = data.modelNodes
    println("Model nodes: ")
    println(model_nodes)
    println("Edge nodes: ")
    println(edge_modes)
    systems_map = get_systems_map(model_nodes)
    connections = get_connection_equations(systems_map, model_nodes, edge_modes)
    println("Connections")
    len = length(connections)
    println("Length: $len")
    for connection in connections
        println(connection)
    end
    @parameters t
    top_level_system = build_top_level_system(t, connections, systems_map)
    simplified_system = structural_simplify(top_level_system)
    ps = build_parameter_map(simplified_system, model_nodes)
    println("Parameter map")
    println(ps)
    write(ws, "simulating")
    sol = solve_system(simplified_system, ps)
    solutions_list = build_solutions_list(top_level_system, sol)
    println("Solutions list: ")
    println(solutions_list)
    write(ws, solutions_list)
    write(ws, "done")
end

function on_estimate_parameters(ws::HTTP.WebSockets.WebSocket, id, data) 
    println("estimate_parameters event received from client $id")
    println("States: ")
    println(data.states)

    edge_modes = data.edgeNodes
    model_nodes = data.modelNodes
    systems_map = get_systems_map(model_nodes)
    connections = get_connection_equations(systems_map, model_nodes, edge_modes)
    @parameters t
    top_level_system = build_top_level_system(t, connections, systems_map)
    simplified_system = structural_simplify(top_level_system)
    pmap = build_parameter_map(simplified_system, model_nodes)

    write(ws, "optimizing")

    prob = get_problem(simplified_system, pmap)

    println("True sols: ")
    true_sols = build_true_sol_list(data.states)
    println(true_sols)

    callback = function (p, l, pred)
        display(l)
        display(p)
        # Tell sciml_train to not halt the optimization. If return true, then
        # optimization stops.
        return false
    end

    function loss(p)
        sol = solve(prob, Rodas4(), p=p)
        current_sols = build_current_sol_list(sol, simplified_system, data.states)
        loss_value = sum(abs2, current_sols .- true_sols)
        return loss_value, sol
    end

    println("initial_ps: ")
    lower_bounds::Vector{Float64} = get_lower_bounds(top_level_system)
    upper_bounds::Vector{Float64} = get_upper_bounds(top_level_system)
    println(lower_bounds)
    result_ode = DiffEqFlux.sciml_train(loss, lower_bounds; lower_bounds=lower_bounds, upper_bounds=upper_bounds, cb = callback)
    println("result ode.u: ")
    println(result_ode.u)
    p_list = get_optimized_parameters(result_ode.u, top_level_system)
    write(ws, "done")
    write(ws, JSON3.write(p_list))
end



