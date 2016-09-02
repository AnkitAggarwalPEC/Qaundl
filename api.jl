import JSON
import Requests
using Requests.get
using Requests.Response

metaDictionary = Dict{UTF8String,Any}()

function getQueryArgs(database_code:: AbstractString , per_page::Int = 100 ,
 sort_by="id" , page::Int = 1 )

    queryArgs = Dict{Any , Any}("database_code" => database_code,
                                "per_page" => per_page,
                                "sort_by" => sort_by,
                                "page" =>page,
                                "api_key" =>getApiKey())

    return queryArgs
end

function insertMetaData()

end
    
end
function getApiKey()
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

function getBaseUrl()
    path = "https://www.quandl.com/api/"
    return path
end


function getListOfDatasets(code::AbstractString)

    if length(code) == 0
        error("Please pass a valid code!")
    end
    final_path = getBaseUrl() * "v3/datasets.json/"
    println(final_path)

    resp = get(final_path , query = getQueryArgs(code))

    abc = Requests.json(resp)

    println(abc)

    #data = split(Requests.text(resp) , "\n")

    #data = JSON.parse(resp.data)

    if resp.status != 200
        println("Error in processing the request")
    end 

end

function set_auth_token(token::AbstractString)

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


println("Starting the quandl")
set_auth_token("JHKaDwdS-RtM26RxPauV")
getListOfDatasets("NSE")
