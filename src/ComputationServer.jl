module ComputationServer

using Genie 
using Logging
using LoggingExtras 
using Revise

function main()

  Core.eval(Main, :(const UserApp = $(@__MODULE__)))

  Genie.genie(; context = @__MODULE__)

  Core.eval(Main, :(const Genie = UserApp.Genie))
  Core.eval(Main, :(using Genie))

end

end
