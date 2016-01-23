defmodule FlakyConnection.Transport do
  defmodule SSL, do: defstruct [:socket]
  defmodule TCP, do: defstruct [:socket]

  def send(%SSL{socket: socket}, data) do
    :ssl.send(socket, data)
  end

  def send(%TCP{socket: socket}, data) do
    :gen_tcp.send(socket, data)
  end

  def setopts(%SSL{socket: socket}, opts) do
    :ssl.setopts(socket, opts)
  end

  def setopts(%TCP{socket: socket}, opts) do
    :inet.setopts(socket, opts)
  end

  def close(%SSL{socket: socket}), do: :ssl.close(socket)
  def close(%TCP{socket: socket}), do: :gen_tcp.close(socket)
end
