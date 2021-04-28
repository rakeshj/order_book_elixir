defmodule Exchange do
  use Application

  def start(_type, _args) do
    IO.puts("Starting the application...")
    Exchange.Supervisor.start_link()
  end
end
