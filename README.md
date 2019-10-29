# ITK Health Checkex

[![CircleCI](https://img.shields.io/circleci/build/github/inside-track/itk_health_checkex.svg)](https://circleci.com/gh/inside-track/itk_health_checkex/tree/master)
[![Hex version badge](https://img.shields.io/hexpm/v/itk_health_checkex.svg)](https://hex.pm/packages/itk_health_checkex)

**Plug based health check provided as macros.**

## Installation

The package can be installed by adding `itk_health_checkex` to your list of dependencies in mix.exs:

```elixir
def deps do
  [
    {:itk_health_checkex, "~> 0.0.3"}
  ]
end
```

After you are done, run `mix deps.get` in your shell to fetch and compile ITK Healthcheckex.

## Configuration

You can config the maximum timeout in seconds allowed for all the checks, if the timeout interval elapsed
and any of the checks wasn't finished; it will terminate all the remaining checks and report them as timedout
and respond with *503* HTTP status code. _default is: `29000` milliseconds == 29 seconds_

Also you can config the endpoint you want to hit to run the checks. _default is: `healthcheck`_

you can define it as follows:

```elixir
config :itk_health_checkex,
  timeout: 10_000,
  endpoint: "healthcheck"
```

## Usage

You will need to define a new plug and use the `HealthCheckex` module under your `lib/project_web/plugs` folder, you can name
it anything you want, ex: `lib/acme_web/plugs/health_check.ex`:

```elixir
defmodule AcmeWeb.HealthCheck do
  use HealthCheckex
end
```

then you will need to tell your endpoint module about this plug, it's better to define it
as early as possible in your endpoint file, just open `lib/acme_web/endpoint.ex` and make the following changes:

```elixir
defmodule AcmeWeb.Endpoint do
  ...
  plug(AcmeWeb.HealthCheck)
  ...
end
```
_Take care that you will need to use the same module name of the plug you defined earlier._

## Defining Checks

You can define all your checks in the plug you created earlier using the `healthcheck` macro;
your check should either return any of these values:

| Return Value      | Result      | Message         | HTTP Response Status Code |
|-------------------|-------------|-----------------|---------------------------|
| `:ok`             | healthy     | "Healthy!"      | 200                       |
| `{:ok, result}`   | healthy     | `result`        | 200                       |
| `{:warn, result}` | healthy     | `result`        | 200                       |
| `{:fail, result}` | not healthy | `result`        | 503                       |
| `_`               | not healthy | Inspected error | 503                       |

_If at least one check returned `{:fail, result}` or timedout then the app will be considered as not healthy, 
and if all the checks return a `{:warn, result}` the app will be considered healthy._

### Examples

```elixir
  healthcheck :redis do
    key = "healthcheck-" <> Ecto.UUID.generate()

    with {:ok, _} <- Redis.set(key, "true"),
         {:ok, "true"} <- Redis.get(key),
         {:ok, 1} <- Redis.delete(key) do
      :ok
    else
      err -> {:fail, err}
    end
  end

  healthcheck :database do
    repos = [ITK.Repo]

    try do
      repos |> Enum.each(&Ecto.Adapters.SQL.query(&1, "select 1"))
      {:ok, "#{length(repos)} Repo(s) Healthy!"}
    rescue
      err -> {:fail, err}
    end
  end

  healthcheck :timedout_service do
    :timer.sleep(40_000)
    :ok
  end
```
