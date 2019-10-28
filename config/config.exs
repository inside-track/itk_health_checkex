use Mix.Config

config :itk_health_checkex,
  timeout: 29_000,
  endpoint: "healthcheck"

case Mix.env() do
  :dev -> import_config "dev.exs"
  :test -> import_config "test.exs"
end
