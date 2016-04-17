defmodule Rumbl do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Start the endpoint when the application starts
      supervisor(Rumbl.Endpoint, []),
      supervisor(Rumbl.InfoSys.Supervisor, []),
      # Start the Ecto repository
      supervisor(Rumbl.Repo, []),

      # Here you could define other workers and supervisors as children
      # worker(Rumbl.Worker, [arg1, arg2, arg3]),

      # restart: options are:
      # :permanent - the child is always restarted (default)
      # :temporary - the child is never restarted
      #     useful when restarting would likely not fix the problem
      #     or just doesn't make sense
      # :transient - the child is restarted only if it terminates abnormally,
      #     with an exit reason other than :normal, :shutdown or {:shutdown, term}
      # other options: max_restarts (default 3) max_seconds (default 5). The defaults
      # mean that if there are more than 3 crashes in a 5 second period, OTP
      # will pass the error up the supervisor tree instead of restarting
      # worker(Rumbl.Counter, [5])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    # :one_for_one - if a child terminates, a supervisor restarts only that process.
    # :one_for_all - if a child terminates, a supervisor terminates all children, and then restarts all children.
    # :rest_for_one - if a child terminates, a supervisor terminates all child processes defined after the one that dies. Then the supervisor restarts all terminated processes.
    # :simple_one_for_one - similar to :one_for_one but used when a supervisor needs to dynamically supervise processes. For example, a web server would use it to supervise web requests, which may be 10 or 100000 concurrently running processes.

    opts = [strategy: :one_for_one, name: Rumbl.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Rumbl.Endpoint.config_change(changed, removed)
    :ok
  end
end
