defmodule DynamicDnsClient.HTTPFakeSuccessful do
  def get(_) do
    {:ok, %HTTPoison.Response{status_code: 200, body: random_ip_v4_address()}}
  end

  defp random_ip_v4_address do
    "#{random_ip_v4_address_part()}.#{random_ip_v4_address_part()}.#{random_ip_v4_address_part()}.#{random_ip_v4_address_part()}"
  end

  defp random_ip_v4_address_part do
    Enum.random(0..255)
  end
end
