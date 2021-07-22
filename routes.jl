using Genie.Router
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