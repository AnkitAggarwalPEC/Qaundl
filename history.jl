function getHistory(symbols :: Array{Any ,1} , 
        dataType :: UTF8String ,
        horizon :: Int ,
        frequency :: Int ,
        year :: Int , date :: UTF8String, exchange :: UTF8String) 

    length = length(symbols)
    for symbol in symbols
        mongoQuery = Dict("ticker" => symbol , "dataSources.frequency" => frequency ,
                        "exchange" => exchange , "dataSources.dataType" => dataType)
        doc = find(securityCollection , mongoQuery)
        securityID = get(doc, "securityID", "NULL")
        if securityID == "NULL"
            println("Data not found")
        else
        dataDoc = find(dataCollection , query("securityID" => securityID , "Year" => year,
                                    "data.source.name" => "Quandl",
                                    "data.source.id" => securityID) )
        dataColoumns = dataDoc["data"]["column"]
        actualData = dataDoc["data"]["column"]["data"]
        end
    end    

end