defmodule FlakyConnectionHandler do
  @behaviour :ranch_protocol

  use GenServer

  alias FlakyConnection.Transport

  require Logger

  def start_link(ref, socket, transport, opts) do
    GenServer.start_link(__MODULE__, [ref, socket, transport, opts])
  end

  def init([ref, socket, transport, [host, port, agent]]) do
    socket = case transport do
      :ranch_tcp -> %Transport.TCP{socket: socket}
      :ranch_ssl -> %Transport.SSL{socket: socket}
    end
    me = self
    #TODO terminate
    Agent.update(agent, &([me | &1]))
    GenServer.cast(self, {:connect, ref, socket, host, port})
    {:ok, nil}
  end

  def handle_call({:latency, time}, _from, state) do
    {:reply, :ok, Dict.put(state, :latency, time)}
  end

  def handle_cast({:connect, ref, socket, host, port}, nil) do
    :ok = :ranch.accept_ack(ref)
    {:ok, remote} = :gen_tcp.connect(host, port, [mode: :binary, active: :once])
    remote = %Transport.TCP{socket: remote}
    Transport.setopts(socket, [active: :once])
    {:noreply, %{local: socket, remote: remote, latency: 0}}
  end

  def handle_info({:send, socket, src, data}, state) do
    :ok = Transport.send(socket, data)
    Transport.setopts(src, [active: :once])
    {:noreply, state}
  end

  def handle_info(
    {proto, socket, data},
    state = %{
      local: local = %{socket: local_socket},
      remote: remote = %{socket: remote_socket},
      latency: latency
    }
  ) when proto in [:ssl, :tcp] do
    IO.inspect {:received, proto, data}
    {src, dest} = case socket do
      ^local_socket -> {local, remote}
      ^remote_socket -> {remote, local}
    end
    Process.send_after(self, {:send, dest, src, data}, latency)
    {:noreply, state}
  end

  def handle_info(
    {closed_msg, socket},
    state = %{
      local: local = %{socket: local_socket},
      remote: remote = %{socket: remote_socket}
    }
  ) when closed_msg in [:ssl_closed, :tcp_closed] do
    IO.inspect {:closing, closed_msg}
    target = case socket do
      ^local_socket -> remote
      ^remote_socket -> local
    end
    Transport.close(target)
    {:stop, :normal, state}
  end
end
