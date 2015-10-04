defmodule FlakyConnection do
  defstruct [:ref, :port, :agent]
  require Logger

  def start(host, port, local_port \\ 0) do
    ref = make_ref
    {:ok, agent} = Agent.start_link(fn -> [] end)
    {:ok, _} = :ranch.start_listener(ref, 100, :ranch_tcp, [port: local_port],
                  FlakyConnectionHandler, [host, port, agent])
    port = :ranch.get_port(ref)
    %__MODULE__{ref: ref, port: port, agent: agent}
  end

  def set_latency(%__MODULE__{agent: agent}, latency) do
    connections = Agent.get(agent, &(&1))  
    Enum.each connections, fn (conn) ->
      :ok = GenServer.call(conn,{:latency, latency})
    end
  end

  def stop(%__MODULE__{ref: ref}) do
    :ranch.stop_listener(ref)
  end
end
