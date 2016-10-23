defmodule Inspire do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Inspire.Repo, []),
      worker(Inspire.Web, [])
    ]

    opts = [strategy: :one_for_one, name: Inspire.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

defmodule Inspire.Web do
  use Plug.Router
  require Logger

  plug Plug.Logger
  plug Plug.Static,
    at: "/",
    from: :inspire
  plug :match
  plug :dispatch

  def init(opts) do
    opts
  end

  def start_link do 
    {:ok, _} = Plug.Adapters.Cowboy.http Inspire.Web, []
  end

  get _ do
    Routers.WebsiteRouter.call(conn, [])
  end
end

defmodule User do
    use Ecto.Model

    schema "users" do
        field :first_name, :string
        field :last_name, :string

        timestamps
    end
end

defmodule Inspire.Repo do
    use Ecto.Repo,
        otp_app: :inspire,
        adapter: Sqlite.Ecto
end
