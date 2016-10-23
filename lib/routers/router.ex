defmodule Routers do
    defmodule Router do
        defmacro __using__(_opts) do
            quote do
                def init(options) do
                    options
                end
                def call(conn, _opts) do
                    route(conn.method, conn.path_info, conn)
                end
            end
        end
    end

    defmodule UserRouter do
        use Router

        def route("GET", ["users", user_id], conn) do
            case Inspire.Repo.get(User, user_id) do
                nil -> 
                    conn |> Plug.Conn.send_resp(404, "User with that ID not found.")
                user ->
                    page_contents = EEx.eval_file("templates/show_user.eex", [user: user])
                    conn 
                    |> Plug.Conn.put_resp_content_type("text/html")
                    |> Plug.Conn.send_resp(200, page_contents)
            end
        end
        def route(_method, _path, conn) do
            conn |> Plug.Conn.send_resp(404, "Couldn't find that page, sorry!")
        end
    end

    defmodule FinanceRouter do
        use Router

        def route("GET", ["finance", symbol], conn) do
            body = Finance.getChartData(5, symbol)
            conn |> Plug.Conn.send_resp(200, body)
        end
    end

    defmodule PhotoRouter do
        use Router

        def route("GET", ["photo", query], conn) do
            response = HTTPotion.get "https://api.flickr.com/services/rest/", query: %{method: "flickr.photos.search", api_key: "18909702572380511bc12de7e265348a", text: query} 
            conn |> Plug.Conn.send_resp(200, response.body)
        end
    end

    defmodule WebsiteRouter do
        use Router

        @user_router_options UserRouter.init([])
        @photo_router_options PhotoRouter.init([])
        @finance_router_options FinanceRouter.init([])
        def route("GET", ["hello"], conn) do
            conn |> Plug.Conn.send_resp(200, "Hello, World!")
        end
        def route("GET", ["photo" | path], conn) do
            PhotoRouter.call(conn, @photo_router_options)
        end
        def route("GET", ["users" | path], conn) do
            UserRouter.call(conn, @user_router_options)
        end
        def route("GET", ["finance" | path], conn) do
            FinanceRouter.call(conn, @finance_router_options)
        end
        def route("GET", ["soundtest"], conn) do
            page_contents = EEx.eval_file("templates/sound_test.eex", [])
            conn 
            |> Plug.Conn.put_resp_content_type("text/html")
            |> Plug.Conn.send_resp(200, page_contents)
        end
        def route(_method, _path, conn) do
            conn |> Plug.Conn.send_resp(404, "Couldn't find that page, sorry!")
        end 
    end
end