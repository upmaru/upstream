use Mix.Config

config :upstream, :upload, timeout: 600_000

config :upstream, :storage,
  account_id: System.get_env("B2_ACCOUNT_ID"),
  application_key: System.get_env("B2_APPLICATION_KEY"),
  bucket_id: System.get_env("B2_BUCKET_ID"),
  bucket_name: System.get_env("B2_BUCKET_NAME"),
  service: "b2"

config :upstream, Upstream,
  concurrency: 2,
  scheduler: true
