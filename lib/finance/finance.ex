defmodule Finance do
    def getChartData(days, symbol) do
       test = Poison.encode!(%{normalized: :false, numberofdays: days, dataperiod: "Day", elements: [%{symbol: symbol, type: "price", params: ["ohlc"]}]})
       HTTPotion.get("http://dev.markitondemand.com/MODApis/Api/v2/InteractiveChart/json", query: %{parameters: test}).body 
    end
end