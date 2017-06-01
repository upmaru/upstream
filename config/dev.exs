use Mix.Config

config :blazay, Blazay,
  account_id: System.get_env("B2_ACCOUNT_ID"),
  application_key: System.get_env("B2_APPLICATION_KEY")