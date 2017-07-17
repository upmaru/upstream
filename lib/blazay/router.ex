defmodule Blazay.Router do
  import Plug.Conn
  use Plug.Router

  plug :match
  plug :dispatch

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison

  post "/upload/chunk" do
    
  end

  post "/upload/file" do
    
  end

end
