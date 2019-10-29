defmodule Checker do
  @moduledoc """
  Health Checks runner.
  """

  alias Report

  @spec run(module(), list(atom()), keyword()) :: %Report{}
  def run(module, checks, options) do
    timeout = options |> Keyword.get(:timeout)
    report = checks |> Report.build()

    checks
    |> Task.async_stream(module, :do_check, [], timeout: timeout, on_timeout: :kill_task)
    |> Enum.reduce(report, &aggregate_result/2)
  end

  defp aggregate_result({:ok, reply}, report), do: report_result(reply, report)
  defp aggregate_result({:exit, :timeout}, report), do: report_result(:timeout, report)
  defp aggregate_result(_, report), do: report

  defp report_result(:timeout, report), do: Report.report_timeout(report)
  defp report_result({:ok, check}, report), do: Report.report_passing(report, check)

  defp report_result({:ok, check, result}, report),
    do: Report.report_passing(report, check, result)

  defp report_result({:fail, check, result}, report),
    do: Report.report_failing(report, check, result)

  defp report_result({:warn, check, result}, report),
    do: Report.report_warning(report, check, result)

  defp report_result(_, report), do: report
end
