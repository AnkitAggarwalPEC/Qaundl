
function getQueryArgs(database_code:: AbstractString , per_page::Int = 100 ,
 sort_by="id" , page::Int = 1 )

    queryArgs = Dict{Any , Any}("database_code" => database_code,
                                "per_page" => per_page,
                                "sort_by" => sort_by,
                                "page" =>page,
                                "api_key" =>getApiKey())

    return queryArgs
end

function getApiKey()
    if !ispath(joinpath(@__FILE__,"../token/"))
        error("Api Key is not initialized")
    end

    api_key = readall(@__FILE__,"../token/auth_token")
    
    if api_key == ""
        println("Empty API Key")
    else
        println("Using API key" , api_key)
    end

    return api_key

end

function getBaseUrl()
    path = "https://www.quandl.com/api/"
    return path
end


function getListOfDatasets(code::AbstractString)

    if(length(code) == 0
        error("Please pass a valid code!")
    end
    final_path = getBaseUrl * "v3/datasets.json/"
    println(final_path)

    resp = get(final_path , query = getQueryArgs(code))

    if resp.status != 200
        println("Error in processing the request")
    end

    


end

function set_auth_token(token::AbstractString)

    if length(token) != 20 && length(token) != 0
        error("Invalid Token : must be 20 characters long or be an empty")
    end

    if !ispath(joinpath(@__FILE__,"../token/"))
        mkdir(joinpath(@__FILE__,"../token/"))
    end

    open(joinpath(@__FILE__,"../token/auth_token"),"w") do token_file
        write(token_file , token)
    end

    return nothing
end