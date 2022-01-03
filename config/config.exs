import Config

config :dynamic_dns_client, http_module: HTTPoison
config :dynamic_dns_client, fetch_env_vars: true
config :dynamic_dns_client, update_google_domains: true

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
