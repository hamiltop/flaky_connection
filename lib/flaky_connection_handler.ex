defmodule FlakyConnectionHandler do
  @behaviour :ranch_protocol

  use GenServer

  require Logger

  def start_link(ref, socket, transport, opts) do
    GenServer.start_link(__MODULE__, [ref, socket, transport, opts])
  end

  def init([ref, socket, _transport, [host, port, agent]]) do
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
    :inet.setopts(socket, [active: :once])
    {:noreply, %{local: socket, remote: remote, latency: 0}}
  end

  def handle_info({:send, socket, data}, state) do
    :ok = :gen_tcp.send(socket, data)
    {:noreply, state}
  end

  def handle_info({:tcp, socket, data}, state = %{local: local, remote: remote, latency: latency}) do
    lookup = fn socket ->
      case socket do
        ^local -> remote
        ^remote -> local
      end
    end
    target = lookup.(socket)
    Process.send_after(self, {:send, target, data}, latency)
    :inet.setopts(socket, [active: :once])
    {:noreply, state}
  end

  def handle_info({:tcp_closed, socket}, state = %{local: local, remote: remote}) do
    lookup = fn socket ->
      case socket do
        ^local -> remote
        ^remote -> local
      end
    end
    target = lookup.(socket)
    :gen_tcp.close(target)
    {:stop, :normal, state}
  end
end
