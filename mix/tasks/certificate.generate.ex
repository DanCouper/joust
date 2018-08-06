defmodule Mix.Tasks.Certificate.Generate do
  use Mix.Task

  @shortdoc "Generate test certificates for local HTTPS development."

  @moduledoc """
  JoustWeb uses HTTP/2, and HTTP/2 necessitates HTTPS. Generate the required certificate
  and save it to `priv/` to allow the app to function properly in developemnt mode.

  NOTE: when the server is started for the first time, the browser will state
  that the connection is not secure and that the certificate was not issued by a
  certificate authority. Just add the URL to the exception list, and everything should
  then work.

  FIXME this does not work, only the key is generated, with no interface for setting up the .pem file.
  The Port (does :os.cmd even use a port????) seems to cloes after the `server.key` file is generated,
  I do not get the std output.
  """
  def run(_args) do
    "openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -keyout priv/server.key -out priv/server.pem"
    |> String.to_charlist()
    |> :os.cmd()
  end
end
