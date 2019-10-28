use Mix.Config

config :itk_health_checkex,
  # just timeout after 500 milliseconds for testing purposes
  timeout: 500,
  endpoint: "healthcheck"
