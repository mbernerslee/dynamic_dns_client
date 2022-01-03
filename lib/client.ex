defmodule DynamicDnsClient.Client do
  use GenServer
  require Logger

  # TODO clean up this mess
  # TODO work out how the google URL hit keeps happening...?

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def child_spec do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []}
    }
  end

  @impl true
  def init(_) do
    env_vars =
      if Application.get_env(:dynamic_dns_client, :fetch_env_vars) do
        get_critical_env_vars!()
      else
        %{}
      end

    case fetch_public_ip() do
      {:ok, ip} ->
        state = Map.put(env_vars, :ip, ip)
        update_google_domains_with_ip(state)
        fetch_public_ip_again_later()
        {:ok, state}

      {:error, error} ->
        {:stop, error}
    end
  end

  @impl true
  def handle_call(:fetch_public_ip, _from, %{ip: ip} = state) do
    IO.inspect(state.ip)

    case fetch_public_ip() |> IO.inspect() do
      {:ok, ^ip} ->
        Logger.info("Public IP is #{ip} [unchanged]")
        fetch_public_ip_again_later()
        {:noreply, state}

      {:ok, new_ip} ->
        IO.inspect("old IP #{ip} - new IP #{new_ip}")
        Logger.info("Public IP is #{ip} [changed!]")
        update_google_domains_with_ip(state)
        fetch_public_ip_again_later()
        {:noreply, %{state | ip: new_ip}}

      {:error, error} ->
        {:stop, error}
    end
  end

  defp update_google_domains_with_ip(state) do
    if Application.get_env(:dynamic_dns_client, :update_google_domains) do
      url =
        "https://#{state.username}:#{state.password}@domains.google.com/nic/update?hostname=#{state.hostname}&myip=#{state.ip}"

      url |> HTTPoison.get() |> parse_update_google_domains_with_ip_response(state.ip)
    end
  end

  defp parse_update_google_domains_with_ip_response(response, ip) do
    case response do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        parse_200_response_body(body, ip)

      {_, error} ->
        Logger.error("Got unexpected response from google domains #{inspect(error)}")
        {:error, error}
    end
  end

  defp parse_200_response_body(body, ip) do
    cond do
      body == "nochg #{ip}" ->
        Logger.info("Google domains says the IP is already to set to #{ip}")
        {:ok, ip}

      body == "Good #{ip}" ->
        Logger.info("Successfully updated google domain to #{ip}")
        {:ok, ip}

      true ->
        Logger.error("Unexpected HTTP 200 response body from google domains #{inspect(body)}")
        {:error, body}
    end
  end

  defp get_critical_env_vars! do
    critial_env_vars = [
      {:username, "GOOGLE_DYNAMIC_DNS_USERNAME"},
      {:password, "GOOGLE_DYNAMIC_DNS_PASSWORD"},
      {:hostname, "GOOGLE_DYNAMIC_DNS_HOSTNAME"}
    ]

    Enum.reduce(critial_env_vars, %{}, fn {key, env_var_name}, acc ->
      case System.get_env(env_var_name) do
        nil ->
          raise "the environment varibale #{env_var_name} was not set, and I can't run without it"

        env_var_value ->
          Map.put(acc, key, env_var_value)
      end
    end)
  end

  defp fetch_public_ip do
    case http_module().get("https://ipinfo.io/ip") do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}

      {:ok, other} ->
        {:error, other}

      {:error, error} ->
        {:error, error}
    end
  end

  defp http_module, do: Application.get_env(:dynamic_dns_client, :http_module)

  defp fetch_public_ip_again_later do
    pid = self()

    spawn_link(fn ->
      :timer.sleep(5_000)
      # :timer.sleep(0)
      GenServer.call(pid, :fetch_public_ip)
    end)
  end
end
