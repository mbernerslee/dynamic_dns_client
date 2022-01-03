import Config

config :dynamic_dns_client, http_module: DynamicDnsClient.HTTPFakeSuccessful
# config :dynamic_dns_client, fetch_env_vars: false
config :dynamic_dns_client, fetch_env_vars: true
config :dynamic_dns_client, update_google_domains: false
