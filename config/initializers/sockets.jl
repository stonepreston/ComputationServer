using HTTP: WebSockets
include("../../lib/socket_handlers.jl")

println("Starting websocket server...")
@async HTTP.WebSockets.listen("127.0.0.1", UInt16(8081)) do ws
    while !eof(ws)
        data = readavailable(ws)
        handleMessage(ws, String(data))
    end
end
