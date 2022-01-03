defmodule DynamicDnsClient.Application do
  use Application
  alias DynamicDnsClient.Client

  def start(_type, _args) do
    children = [Client.child_spec()]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
