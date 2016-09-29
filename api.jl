import JSON
import Requests
using Requests.get
using Requests.Response

using Mongo
"""
global definition of dictionary to store metadata per database
"""
metaDictionary = Dict{UTF8String,Dict{UTF8String,Any}}()
"""
global definition of mongodb client
"""
client = MongoClient()
securityCollection = MongoCollection(client,"aimsqaunt","security") 

dataCollection = MongoCollection(client , "aimsquant","data")
"""
function to return the GET arguements for downloading the meta data for
the datasets in the particular database defined by database_code
"""
function getqueryargs(database_code:: AbstractString; per_page::Int = 100 ,
 sort_by="id" , page::Int = 1 )

    queryArgs = Dict{Any , Any}("database_code" => database_code,
                                "per_page" => per_page,
                                "sort_by" => sort_by,
                                "page" =>page,
                                "api_key" =>getapikey())

    return queryArgs
end

"""
function to insert metadata per database
"""
function insertmetadata(database_code::AbstractString , data :: Dict{UTF8String,Any})
    metaDictionary[database_code] = data

    #To check if insertion is successful
    temp = get(metaDictionary , database_code , 0)

    if temp == 0
        error("Error in insertion")
        return false
    else
        return true

    end
end

"""
function to get the metadata from the metadata database
"""
function getmetadata(database_code::AbstractString) 

   temp = get(metaDictionary , database_code , 0)

    if temp == 0
        error("Value doesn't exist in database")
        return false
    else
        return temp

    end 
end

"""
function to get the Quandl API key
"""
function getapikey()
    if !ispath(joinpath(pwd(),"token/"))
        error("Api Key is not initialized")
    end

    api_key = readall(joinpath(pwd(),"token/auth_token"))
    
    if api_key == ""
        println("Empty API Key")
    else
        println("Using API key " , api_key)
    end

    return api_key

end

"""
function to get the basic url for the Quandl
"""
function getbaseurl()
    path = "https://www.quandl.com/api/"
    return path
end

"""
function to download the metadata for all the datasets present in the database ("NSE" , "WIKI")
"""
function getlistofdatasets(code::AbstractString)

    if length(code) == 0
        error("Please pass a valid code!")
    end
    final_path = getbaseurl() * "v3/datasets.json/"
    
    resp = get(final_path , query = getqueryargs(code))

    if resp.status != 200
        println("Error in processing the request")
    end 

    data = Requests.json(resp)

    insertmetadata(code , data["meta"])

    #println(data["meta"])

    #println ("Reached here")
    storealldatasetscode(code)
    return nothing
end
"""
function to check if data exists in mongodb document
"""
function checkifexistsinmongodbdocument(collection:: MongoCollection , data :: Dict{UTF8String,Any} )
    dataCount = count(collection , data)

    if dataCount == 0
        return false
    else
        return true
    end
end

"""
function to insert security data
The data is not available in Quandl Dataset for the started trading day and ended trading day , So if another data source is added then its needed to modified
"""
function insertintosecuritydocument(data :: Dict{UTF8String,Any})

    securityID = get(data , "id" , "NULL")
    ISIN = get(data , "ISIN" , "NULL")
    ticker = get(data , "dataset_code" , "NULL")
    exchange = get(data , "database_code" , "NULL")
    frequency = get(data , "frequency" , "NULL")
    dataType = get(data , "type" , "NULL")
    sourceName  = "Quandl"
    QuandlDict = Dict{Any,Any}("name" => sourceName,
                               "id" => get(data , "id" , "NULL"),
                               "newest_available_date" => get(data , "newest_available_date" , "NULL"),
                               "oldest_available_date" => get(data , "oldest_available_date" , "NULL"),
                               "refreshed_at" => get(data ,"refreshed_at"  , "NULL"),
                               "description" => get(data , "description" , "NULL"),
                               "dataset_code" => get(data , "dataset_code" , "NULL"),
                               "database_code" => get(data , "database_code" , "NULL"))

    dataDict = Dict{Any , Any}("dataType" => dataType,
                                "frequency" => frequency,
                                "source" => QuandlDict
                              )
    securityData = Dict{Any , Any}("securityID" => securityID,
        "ISIN" => ISIN,
        "ticker" => ticker,
        "exchange" => exchange,
        "name" => sourceName,
        "dataSources" => dataDict)
    insert(securityCollection , securityData)


end


"""
function to extract all the datasets code from metadata
"""
function storealldatasetscode(code::AbstractString)

    if length(code) == 0
        error("Please pass a valid code!")
    end
    metaDict = getmetadata(code)
    final_path = getbaseurl() * "v3/datasets.json/"
    
    if metaDict == false
        error(code * "data doesn't exist in database !!!")
    else 
        total_pages = metaDict["total_pages"]
        for i = 1:total_pages
            resp = get(final_path , query = getqueryargs(code , page = i))
            
            if resp.status != 200
                error("Error in processing the query")
            else
                respJSON = Requests.json(resp)
                dataArray = respJSON["datasets"]
                len = length(dataArray)
                for j = 1:len
                    dataset  = dataArray[j]
                    println(dataset)
                    insertintosecuritydocument(dataset)
                    database_code = dataset["database_code"]
                    dataset_code = dataset["dataset_code"]
                    getDataURL = getbaseurl() *  "v3/datasets/" *database_code * "/" * dataset_code *".json" 
                    queryArgs = Dict{Any , Any}("api_key" => getapikey())
                    dataResp = get(getDataURL , query = queryArgs)
                    #println(dataResp)
                    #println ("Reached here in loop")
                    if dataResp.status != 200   
                        error("Error in processing the query dataset_code query")
                    else
                        dataRespJSON = Requests.json(dataResp)
                        handlesecuritydata(dataRespJSON["dataset"])    
                        
                    end
                end
            end
        end
    end
end 

"""
function to insert in data document
"""
function insertindatadocument(securityID::AbstractString,column, data :: Dict{Int , Array{Any , 1}})

    for k in keys(data)
        data = get(data , k, "NULL")
        if data == "NULL"
            println("Something Wrong While inserting Data")
        else
            year  = k 
            quandlData = Dict{Any ,Any}("priority" => 1,
                                        "source" => Dict{Any,Any}("name" => "Quandl","id" => securityID),
                                        "column" =>column,
                                        "data" => data
                                        )
            toInsertDict = Dict{Any ,Any}("securityID" => securityID , "Year" => year , "data" => quandlData)
            insert(dataCollection , toInsertDict)
        end
        
    end
end

"""
function to handle Data for each security
"""
function handlesecuritydata(data :: Dict{UTF8String,Any})
    securityID = get(data , "id" , "NULL")
    column = get(data ,"column", "NULL")
    source = Dict{Any ,Any}("name" => "Quandl" , 
                            "id" => securityID)
    dataToInsert = filterdata(data["data"])

    #insertindatadocument(securityID,column,dataToInsert)

end

"""
function to filter data base on year
"""
function filterdata(data :: Array{Any , 1})
    length  = length(data)
    dataPerYear = Dict{Int, Array{Any , 1}}
    previousDate = 0
    arr = Array{Any , 1}[]
    for i = 1 : length
        dataRow = data[i]
        date = parse(Int , (split(dataRow[1] , "-")[1]) )
        if date == previousDate
           push!(arr , dataRow) 
        else
            if previousDate == 0
                nothing
            else
                insert!(dataPerYear ,previousDate , arr)
            end
            arr = Array{Any , 1}[]
            previousDate = date
            push!(arr , dataRow)
        end    
    end
    return dataPerYear
end
"""
function to set the Quandl API key
"""

function setauthtoken(token::AbstractString)

    if length(token) != 20 && length(token) != 0
        error("Invalid Token : must be 20 characters long or be an empty")
    end
    println(pwd())

    a = joinpath(pwd(),"token")
    println("Printing the path")
    println(a)
    if !ispath(joinpath(pwd(),"token/"))
        println("Creating new directory")
        mkdir(joinpath(pwd(),"token"))
    end

    open(joinpath(pwd(),"token/auth_token"),"w") do token_file
        write(token_file , token)
    end

    return nothing
end

#println("Starting the quandl")
#setauthtoken("JHKaDwdS-RtM26RxPauV")
getlistofdatasets("NSE")
