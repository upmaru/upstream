defmodule Blazay.B2.Download do
  @moduledoc """
  Handles download requests to the b2 api
  """

  alias Blazay.B2.Download.{
    Authorization
  }

  def authorize(prefix, duration) do
    Authorization.call(
      body: [
        prefix: prefix, duration: duration
      ]
    )
  end

  def url(file_name, authorization) do
    
  end
end
