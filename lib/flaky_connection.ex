defmodule FlakyConnection do
  
  defstruct [:ref, :port]
  require Logger

  def start(host, port, local_port \\ 0) do
    ref = make_ref
    {:ok, _} = :ranch.start_listener(ref, 100, :ranch_tcp, [port: local_port],
                  FlakyConnectionHandler, [host, port])
    port = :ranch.get_port(ref)
    %__MODULE__{ref: ref, port: port} 
  end

  def stop(%__MODULE__{ref: ref}) do
    :ranch.stop_listener(ref)  
  end
end
