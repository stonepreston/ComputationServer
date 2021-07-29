using Genie.Router
using Genie.Requests
using JSON

route("/") do
  serve_static_file("welcome.html")
end

route("/categorized_models") do
  JSON.json(ComputationServer.categorized_models)
end





