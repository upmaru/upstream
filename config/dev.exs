use Mix.Config

config :upstream, Upstream,
  account_id: System.get_env("B2_ACCOUNT_ID"),
  application_key: System.get_env("B2_APPLICATION_KEY"),
  bucket_id: System.get_env("B2_BUCKET_ID"),
  bucket_name: System.get_env("B2_BUCKET_NAME"),
  redis_url: "redis://127.0.0.1:6379/1",
  upload_timeout: 0,
  concurrency: 2,
  scheduler: true
