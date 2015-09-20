defmodule FlakyConnectionHandler do
  @behaviour :ranch_protocol

  def start_link(ref, socket, transport, opts) do
    pid = spawn_link(__MODULE__, :init, [ref, socket, transport, opts])
    {:ok, pid}
  end

  def init(ref, socket, _transport, [host, port]) do
    :ok = :ranch.accept_ack(ref)
    {:ok, remote} = :gen_tcp.connect(host, port, [mode: :binary, active: :once])
    :inet.setopts(socket, [active: :once])
    loop(socket, remote)
  end

  defp loop(local, remote) do
    lookup = fn socket ->
      case socket do
        ^local -> remote
        ^remote -> local
      end
    end
    receive do
      {:tcp, socket, data}  ->
        target = lookup.(socket)
        :ok = :gen_tcp.send(target, data)  
        :inet.setopts(socket, [active: :once])
        loop(local, remote)
      {:tcp_closed, socket} -> 
        target = lookup.(socket)
        :gen_tcp.close(target)
    end
  end
end
