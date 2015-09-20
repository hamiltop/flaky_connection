defmodule FlakyConnectionTest do
  use ExUnit.Case

  test "proxying data should work" do
    # This test is pretty hackish, but it accomplishes what it needs to do without
    # requiring excessive synchronization. Basically, we listen on a port in another
    # process and then transfer control back to the main test process. Then we can 
    # fairly easily handle both sides of the connection.
    parent = self
    task = Task.async fn ->
      {:ok, l_sock} = :gen_tcp.listen(11111, [:binary, active: false])
      {:ok, sock} = :gen_tcp.accept(l_sock)
      :gen_tcp.controlling_process(sock, parent)
      sock
    end
    conn = FlakyConnection.start('localhost', 11111)
    {:ok, sock} = :gen_tcp.connect('localhost', conn.port, [:binary, active: false])
    remote_sock = Task.await task
    :inet.setopts(remote_sock, [active: :once])
    :gen_tcp.send(sock, "ping")
    :inet.setopts(sock, [active: :once])
    receive do
      {:tcp, ^remote_sock, "ping"} -> :gen_tcp.send(remote_sock, "pong")
    end
    :inet.setopts(remote_sock, [active: :once])
    receive do
      {:tcp, ^sock, "pong"} -> :ok
    end
    :inet.setopts(sock, [active: :once])
    FlakyConnection.stop(conn)
    receive do
      {:tcp_closed, ^remote_sock} -> :ok
    end
    receive do
      {:tcp_closed, ^sock} -> :ok
    end
  end
end
