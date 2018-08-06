# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :joust, JoustWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "pEWjip7MhiZmE5g5bRxPPeVFly+Iz3gMZri4xW8mU1rDPcuhBPSxT4ZeW0f27ojw",
  render_errors: [view: JoustWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Joust.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
