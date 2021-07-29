using HTTP: WebSockets
using JSON
using HTTP
using Match
clients = Dict{String, HTTP.WebSockets.WebSocket}()

function handleMessage(ws::HTTP.WebSockets.WebSocket, message::String) 
    message = JSON.parse(message);
    id = message["id"]
    event = message["event"]
    data = message["data"]

    println("Client: $id sent event $event with data $data")

    @match event begin
        "disconnect" => WebSockets.close(ws)
    end

end

println("Starting websocket server...")
@async HTTP.WebSockets.listen("127.0.0.1", UInt16(8081)) do ws
    while !eof(ws)
        data = readavailable(ws)
        handleMessage(ws, String(data))
    end
end

