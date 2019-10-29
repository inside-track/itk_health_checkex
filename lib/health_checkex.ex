defmodule HealthCheckex do
  @moduledoc """
  Documentation for ITK Healthcheckex.
  """

  @doc """
  Macro that hold the health check logic and assign it a meaningful name for easy referencing.

  You should either return in the check block one of these values:
  `:ok`
  `{:ok, result}`
  `{:warn, result}`
  `{:fail, result}`

  Returns `{:ok, :service} | {:ok, :service, result} | {:fail, :service, result} | {:warn, :service, result} | {:error, :service, "Didn't get the right response from the check."}`

  ## Examples
      iex> healthcheck(:service, do: :ok)
      {:ok, :service}

      iex> healthcheck(:service, do: {:ok, "message"})
      {:ok, :service, "message"}

      iex> healthcheck(:service, do: {:warn, "message"})
      {:warn, :service, "message"}

      iex> healthcheck(:service, do: {:fail, "message"})
      {:fail, :service, "message"}

      iex> healthcheck(:service, do: :something_else)
      {:error, service, "Didn't get the right response from the check."}
  """
  defmacro healthcheck(name, do: block) do
    quote do
      @health_checks unquote(name)
      @dialyzer {:no_match, do_check: 1}

      def do_check(unquote(name)) do
        unquote(block)
        |> case do
          :ok ->
            {:ok, unquote(name)}

          {:ok, result} ->
            {:ok, unquote(name), result}

          {:fail, result} ->
            {:fail, unquote(name), inspect(result)}

          {:warn, result} ->
            {:warn, unquote(name), inspect(result)}

          _ ->
            {:error, unquote(name), "Didn't get the right response from the check."}
        end
      rescue
        err -> {:error, unquote(name), inspect(err)}
      end
    end
  end

  defmacro __using__(_options) do
    quote do
      Module.register_attribute(__MODULE__, :health_checks, accumulate: true)

      import HealthCheckex
      import Plug.Conn

      @before_compile HealthCheckex
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def init(options), do: options

      def call(conn, _options) do
        options = Application.get_all_env(:itk_health_checkex)

        options |> Keyword.get(:endpoint) |> do_call(conn, options)
      end

      def do_call(endpoint, conn = %Plug.Conn{path_info: [path], method: "GET"}, options)
          when path == endpoint do
        {code, report} =
          __MODULE__
          |> Checker.run(@health_checks, options)
          |> Report.generate()

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(code, Jason.encode!(report))
        |> halt()
      end

      def do_call(_endpoint, conn, _options), do: conn
    end
  end
end
