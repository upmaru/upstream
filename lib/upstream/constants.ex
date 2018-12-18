defmodule Upstream.Constants do
  defmacro __using__(_) do
    quote do
      @uploading "upstream:uploading"
      @errored "upstream:errored"
    end
  end
end
