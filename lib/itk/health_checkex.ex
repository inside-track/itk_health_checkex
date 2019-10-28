defmodule ITK.HealthCheckex do
  @moduledoc """
  Documentation for ITK Healthcheckex.
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

      import ITK.HealthCheckex
      import Plug.Conn

      @before_compile ITK.HealthCheckex
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def init(options), do: options

      def call(conn = %Plug.Conn{path_info: [endpoint], method: "GET"}, _options) do
        options = Application.get_all_env(:itk_health_checkex)

        options |> Keyword.get(:endpoint) |> do_call(conn, options)
      end

      def do_call(endpoint, conn = %Plug.Conn{path_info: [path], method: "GET"}, options)
          when path == endpoint do
        {code, report} =
          __MODULE__
          |> ITK.Checker.run(@health_checks, options)
          |> ITK.Report.generate()

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(code, Jason.encode!(report))
        |> halt()
      end

      def do_call(_endpoint, conn, _options), do: conn
    end
  end
end
