ExUnit.start()

defmodule HealthCheckerPlug do
  use HealthCheckex
end

# Plug Testing dummies for the health check.
defmodule HealthyPlug do
  use HealthCheckex

  healthcheck(:service_3, do: {:warn, RuntimeError})
  healthcheck(:service_2, do: {:ok, "some result message"})
  healthcheck(:service_1, do: :ok)
end

defmodule FailedPlug do
  use HealthCheckex

  healthcheck(:service_1, do: {:fail, TryClauseError})
end

defmodule TimeoutPlug do
  use HealthCheckex

  # :timer.sleep returns :ok after finishing
  healthcheck(:service_1, do: :timer.sleep(700))
  healthcheck(:service_2, do: :ok)
end

defmodule NonMatchedCheckResponsePlug do
  use HealthCheckex

  healthcheck(:service_1, do: {:other, "some other reason"})
end
