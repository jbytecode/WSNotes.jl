module WSNotes

using SQLite, HTTP, JSON 

export run 

struct Note 
    id::UInt64
    datetime::AbstractString 
    subject::AbstractString
    content::AbstractString
end 

function run(; host::String="localhost", port::Int=8000, dbpath::String="notes.db")

    corshandler(request, client) = true 

    function messagehandler(ws)
        for rawmessage in ws
            jsonmessage = rawmessage isa AbstractString ? rawmessage : String(rawmessage)
            parsedmessage = JSON.parse(jsonmessage)
            type = get(parsedmessage, "type", nothing)
            if type == "ping"
                retmessage = JSON.json(Dict("type" => "pong"))
                HTTP.WebSockets.send(ws, retmessage)
            elseif type == "shutdown"
                HTTP.WebSockets.forceclose(ws)
                @info "WSNotes.jl server is shutting down."
                exit(0)
            else 
                retmessage = JSON.json(Dict("type" => "error", "message" => "unknown message type $type"))
                HTTP.WebSockets.send(ws, retmessage)
            end
        end
    end

    @info "WebSocket server running on $host:$port, using database at $dbpath"
    @info "Open the index.html file in the browser to connect to the server and start taking notes."
    HTTP.WebSockets.listen(messagehandler, host, port, check_origin=corshandler)
    # Code is blocking, so the server will keep running until it is shut down by a "shutdown" message or by interrupting the process.
end 



end # module WSNotes
