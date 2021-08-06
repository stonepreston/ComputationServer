using HTTP: WebSockets
using JSON3
using HTTP
using Match
include("./model_builder.jl")

clients = Dict{String, HTTP.WebSockets.WebSocket}()

function handleMessage(ws::HTTP.WebSockets.WebSocket, message::String) 

    message = JSON3.read(message)
    id = message["id"]
    event = message["event"]
    data = message["data"]
    println("Raw message: ")
    println(message)
    println("Client: $id sent event $event with data $data")
    println("**********************************************************************")

    @match event begin
        "connect" => on_connect(ws, id)
        "disconnect" => on_disconnect(ws, id)
        "build_model" => on_build_model(ws, id, data)
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
    sol = solve_system(simplified_system, ps)
    solutions_list = build_solutions_list(top_level_system, sol)
    println("Solutions list: ")
    println(solutions_list)
    write(ws, solutions_list)
end


