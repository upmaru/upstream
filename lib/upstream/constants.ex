defmodule Upstream.Constants do
  defmacro __using__(_) do
    quote do
      @uploading "upstream:uploading"
      @errored "upstream:errored"

      @b2_upload Application.get_env(:upstream, :b2_upload) || Upstream.B2.Upload
      @b2_large_file Application.get_env(:upstream, :b2_large_file) || Upstream.B2.LargeFile
    end
  end
end
