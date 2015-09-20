FlakyConnection
===============

When writing a library such as a database driver, dealing with network failures
is an absolute requirement. Writing automated tests for such situations becomes
tricky. Enter `FlakyConnection`.

Usage
===============

```elixir
conn = FlakyConnection.start('localhost', 1234)

# Connect to localhost and the new port
DatabaseFoo.connect('localhost', conn.port)

# Call FlakyConnection.stop(conn) whenever you want to force a disconnect
FlakyConneciton.stop(conn)
```


Roadmap
===============

There are probably a bunch of other ways to emulate a bad network. First thought
that comes to mind is adding latency.
