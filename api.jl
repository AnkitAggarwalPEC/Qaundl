import JSON
import Requests
using Requests.get
using Requests.Response

"""
global definition of dictionary to store metadata per database
"""
metaDictionary = Dict{UTF8String,Dict{UTF8String,Any}}()


"""
function to return the GET arguements for downloading the meta data for
the datasets in the particular database defined by database_code
"""
function getqueryargs(database_code:: AbstractString , per_page::Int = 100 ,
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
function insertmetadata(database_code::UTF8String , data :: Dict{UTF8String,Any})
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
function getmetadata(code::UTF8String) 

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

    storealldatasetscode(code)
    return nothing
end

"""
funciton to extract all the datasets code from metadata
"""
function storealldatasetscode(code::AbstractString)

    if length(code) == 0
        error("Please pass a valid code!")
    end
    metaDict = getmetadata(code)

    if metaDict == false
        error(code * "data doesn't exist in database !!!")
    else 
        total_pages = metaDict["total_pages"]
        for i = 1:total_pages

        end
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


"""
    Some random code
"""
println("Starting the quandl")
setauthtoken("JHKaDwdS-RtM26RxPauV")
getlistofdatasets("NSE")
