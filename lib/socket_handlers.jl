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
    systems = get_systems(model_nodes)
    println(systems)
end


