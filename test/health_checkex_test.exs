defmodule HealthCheckexTest do
  use ExUnit.Case
  # doctest HealthCheckex
  # alias HealthCheckex

  use Plug.Test

  @opts HealthCheckerPlug.init([])

  setup do
    conn = conn(:get, options(:endpoint))
    conn = HealthCheckerPlug.call(conn, @opts)
    {:ok, %{conn: conn}}
  end

  test "it ignores all other paths" do
    assert :get |> conn("/foo") |> HealthCheckerPlug.call(@opts) |> Map.get(:state) == :unset
  end

  test "it responds to the defined endpoint", %{conn: conn} do
    assert conn.status == 200
    assert conn.halted == true
  end

  test "it responds with correct content-type header", %{conn: conn} do
    assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
  end

  defp options(key), do: Application.get_env(:itk_health_checkex, key)
end
