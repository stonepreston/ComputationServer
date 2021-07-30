using Genie.Router
using Genie.Requests
using JSON

route("/") do
  serve_static_file("welcome.html")
end

route("/categorized_models") do
  JSON.json(ComputationServer.categorized_models)
end

function force_compile()
  sleep(5)

  for (name, r) in Router.named_routes()
    Genie.Requests.HTTP.request(r.method, "http://localhost:8000" * tolink(name))
  end
end

@async force_compile()





