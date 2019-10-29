defmodule ReportTest do
  use ExUnit.Case
  doctest Report
  alias Report

  test "build/1" do
    report = Report.build([:service_1, :service_2])

    assert 2 = report.checks |> length()
    assert 200 = report.http_code

    [:passing, :failing, :warning, :timeout]
    |> Enum.each(fn bucket ->
      assert 0 = report |> Map.get(bucket) |> length()
    end)
  end

  test "report_passing/3 and report_warning/3" do
    report =
      Report.build()
      |> Report.report_passing(:service_1)
      |> Report.report_passing(:service_2, "some message")
      |> Report.report_warning(:service_3, "some warning message")

    assert 2 = report.passing |> length()
    assert 1 = report.warning |> length()
    assert 200 = report.http_code
    assert "Healthy!" = report |> Map.get(:service_1)
    assert "some message" = report |> Map.get(:service_2)
    assert "some warning message" = report |> Map.get(:service_3)
  end

  test "report_failing/3" do
    report =
      Report.build()
      |> Report.report_passing(:service_1)
      |> Report.report_failing(:service_2, "some fail message")

    assert 1 = report.passing |> length()
    assert 1 = report.failing |> length()
    assert 503 = report.http_code
    assert "some fail message" = report |> Map.get(:service_2)
    assert "Healthy!" = report |> Map.get(:service_1)
  end

  test "report_timeout/1" do
    report =
      [:service_1, :service_2, :service_3, :service_4]
      |> Report.build()
      |> Report.report_passing(:service_1)
      |> Report.report_warning(:service_2, "some warning message")
      |> Report.report_timeout()

    assert 1 = report.passing |> length
    assert 1 = report.warning |> length
    assert 2 = report.timeout |> length
    assert 503 = report.http_code
    assert "Healthy!" = report |> Map.get(:service_1)
    assert "some warning message" = report |> Map.get(:service_2)
  end

  test "generate/1" do
    report =
      Report.build()
      |> Report.report_passing(:service_1)

    assert {
             200,
             %{
               service_1: "Healthy!",
               services: %{
                 passing: [:service_1]
               }
             }
           } = Report.generate(report)

    report =
      [:service_1, :service_2, :service_3, :service_4]
      |> Report.build()
      |> Report.report_passing(:service_1)
      |> Report.report_warning(:service_2, "some warning message")
      |> Report.report_failing(:service_3, "some fail message")
      |> Report.report_timeout()

    assert {
             503,
             %{
               service_1: "Healthy!",
               service_2: "some warning message",
               service_3: "some fail message",
               services: %{
                 passing: [:service_1],
                 failing: [:service_3],
                 warning: [:service_2],
                 timeout: [:service_4]
               }
             }
           } = Report.generate(report)
  end
end
