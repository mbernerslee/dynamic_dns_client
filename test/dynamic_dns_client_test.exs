defmodule DynamicDnsClientTest do
  use ExUnit.Case
  doctest DynamicDnsClient

  test "greets the world" do
    assert DynamicDnsClient.hello() == :world
  end
end
