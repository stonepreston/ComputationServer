using Genie.Router
using Genie.Requests
using JSON

route("/") do
  serve_static_file("welcome.html")
end

route("/model_keys") do
  JSON.json(ComputationServer.get_model_keys())
end

route("/model_categories") do
  JSON.json(ComputationServer.model_categories)
end

route("/connectors") do 
  key = getpayload(:key, nothing)
  if !isequal(key, nothing)
    return JSON.json(ComputationServer.get_connections_for_model_key(key))
  end

  return JSON.json([])
end