defmodule CheckerTest do
  use ExUnit.Case
  alias Checker

  describe "run/3" do
    test "all passing" do
      report = HealthyPlug |> Checker.run([:service_2, :service_1], options())

      assert 200 = report.http_code
      assert 2 = report.passing |> length
    end

    test "passing with some warnings" do
      report = HealthyPlug |> Checker.run([:service_3, :service_2, :service_1], options())

      assert 200 = report.http_code
      assert 2 = report.passing |> length
      assert 1 = report.warning |> length
      assert [:service_3] = report.warning
    end

    test "failures" do
      report = FailedPlug |> Checker.run([:service_1], options())

      assert 503 = report.http_code
      assert 1 = report.failing |> length
    end

    test "timeouts" do
      report = TimeoutPlug |> Checker.run([:service_2, :service_1], options())

      assert 503 = report.http_code
      assert 1 = report.passing |> length
      assert 1 = report.timeout |> length
      assert [:service_1] = report.timeout
    end
  end

  defp options(), do: Application.get_all_env(:itk_health_checkex)
end
