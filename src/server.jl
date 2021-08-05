using HTTP
using JSON3
using Sockets 
include("./socket_handlers.jl")
include("./model_types.jl")
include("./models.jl")

StructTypes.StructType(::Type{HTTP.Messages.Response}) = StructTypes.Struct()

# CORS headers and content type headers
headers = [
    "Access-Control-Allow-Origin" => "*",
    "Access-Control-Allow-Headers" => "Content-Type",
    "Access-Control-Allow-Methods" => "POST, GET, OPTIONS",
    "Content-Type" =>  "text/plain"
]

#= CorsHandler: handles preflight request with the OPTIONS flag
If a request was recieved with the correct headers, then a response will be 
sent back with a 200 code, if the correct headers were not specified in the request,
then a CORS error will be recieved on the client side

Since each request passes throught the CORS Handler, then if the request is 
not a preflight request, it will simply go to the JSONHandler to be passed to the
correct service function =#
function CorsHandler(req)
    println(req.headers)
    return HTTP.handle(ROUTER, req)
end


function get_categorized_models(req::HTTP.Request)
    println("Handling request for /categorized_models")
    return HTTP.Response(200, headers; body=JSON3.write(categorized_models))
end

const ROUTER = HTTP.Router()
HTTP.@register(ROUTER, "GET", "/categorized_models", get_categorized_models)

println("Starting web server...")
@async HTTP.serve(ROUTER, ip"127.0.0.1", 8000)


println("Starting websocket server...")
@async HTTP.WebSockets.listen("127.0.0.1", UInt16(8081)) do ws
    while !eof(ws)
        data = readavailable(ws)
        handleMessage(ws, String(data))
    end
end

