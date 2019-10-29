defmodule Report do
  @moduledoc """
  Health checks results report.
  """

  defstruct http_code: 200, passing: [], failing: [], warning: [], timeout: [], checks: []

  @type t :: %__MODULE__{
          http_code: 200 | 503,
          passing: list(atom()),
          failing: list(atom()),
          warning: list(atom()),
          timeout: list(atom()),
          checks: list(atom())
        }

  @spec build(checks :: list(atom())) :: t
  def build(checks \\ []) do
    %__MODULE__{checks: checks}
  end

  @spec report_passing(report :: t, check :: atom(), result :: String.t()) :: t
  def report_passing(report, check, result \\ "Healthy!") do
    %__MODULE__{report | passing: report.passing ++ [check]}
    |> Map.put(check, result)
  end

  @spec report_failing(report :: t, check :: atom(), result :: String.t()) :: t
  def report_failing(report, check, result) do
    %__MODULE__{report | failing: report.failing ++ [check], http_code: 503}
    |> Map.put(check, result)
  end

  @spec report_warning(report :: t, check :: atom(), result :: String.t()) :: t
  def report_warning(report, check, result) do
    %__MODULE__{report | warning: report.warning ++ [check]}
    |> Map.put(check, result)
  end

  @spec report_timeout(report :: t) :: t
  def report_timeout(report) do
    (report.checks -- (report.passing ++ report.failing ++ report.warning))
    |> Enum.reduce(report, &report_timeout_check(&2, &1))
  end

  defp report_timeout_check(report, check) do
    %__MODULE__{report | timeout: report.timeout ++ [check], http_code: 503}
  end

  @spec generate(report :: t) :: {200, map()} | {503, map()}
  def generate(report) do
    {
      report.http_code,
      report
      |> Map.drop([:__struct__, :checks, :http_code, :passing, :failing, :warning, :timeout])
      |> Map.merge(%{
        services: Map.take(report, [:passing, :failing, :warning, :timeout])
      })
    }
  end
end
