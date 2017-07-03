defmodule Blazay.Uploader.File do
  @moduledoc """
  the File Uploader module handles uploading of simple files, generally
  files that can't be used with the large_file api, so files less than 100 MB
  in size.
  """
  use GenServer


end
