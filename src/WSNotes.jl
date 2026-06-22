module WSNotes


using SQLite, HTTP, JSON 


include("DB.jl")
import .DB

export run, HTTP


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
                @info "Shutdown message received. Closing WebSocket connection and shutting down the server..."
                DB.closedb(db)
                exit(0)
            elseif type == "addnote"
                datetime = get(parsedmessage, "datetime", "")
                subject = get(parsedmessage, "subject", "")
                content = get(parsedmessage, "content", "")
                id = DB.addnote(db, datetime, subject, content)
                retmessage = JSON.json(Dict("type" => "addnote_response", "id" => id))
                HTTP.WebSockets.send(ws, retmessage)
            elseif type == "updatenote"
                id = parse(Int64, parsedmessage["id"])
                datetime = get(parsedmessage, "datetime", "")
                subject = get(parsedmessage, "subject", "")
                content = get(parsedmessage, "content", "")
                DB.updatenote(db, id, datetime, subject, content)
                retmessage = JSON.json(Dict("type" => "updatenote_response", "id" => id, "subject" => subject, "content" => content))
                HTTP.WebSockets.send(ws, retmessage)
            elseif type == "deletenote"
                id = parse(Int64, parsedmessage["id"])
                DB.deletenote(db, id)
                retmessage = JSON.json(Dict("type" => "deletenote_response", "id" => id))
                HTTP.WebSockets.send(ws, retmessage)
            elseif type == "getnote"
                id = parse(Int64, parsedmessage["id"])
                note = DB.getnote(db, id)
                if note === nothing
                    retmessage = JSON.json(Dict("type" => "error", "message" => "note with id $id not found"))
                else
                    retmessage = JSON.json(Dict("type" => "getnote_response", "note" => Dict("id" => note.id, "datetime" => note.datetime, "subject" => note.subject, "content" => note.content)))
                end
                HTTP.WebSockets.send(ws, retmessage)
            elseif type == "getnotes"
                notes = DB.getnotes(db)
                noteslist = [Dict("id" => note.id, "datetime" => note.datetime, "subject" => note.subject, "content" => note.content) for note in notes]
                retmessage = JSON.json(Dict("type" => "getnotes_response", "notes" => noteslist))
                HTTP.WebSockets.send(ws, retmessage)
            elseif type == "searchnotes"
                query = get(parsedmessage, "keyword", "")
                notes = DB.searchkeyword(db, query)
                noteslist = [Dict("id" => note.id, "datetime" => note.datetime, "subject" => note.subject, "content" => note.content) for note in notes]
                retmessage = JSON.json(Dict("type" => "searchnotes_response", "notes" => noteslist))
                HTTP.WebSockets.send(ws, retmessage)
            else 
                retmessage = JSON.json(Dict("type" => "error", "message" => "unknown message type $type"))
                HTTP.WebSockets.send(ws, retmessage)
            end
        end
    end

    @info "Creating database connection to $dbpath..."
    db = DB.opendb(dbpath)
    DB.createtables(db) # if not exist.

    @info "WebSocket server running on $host:$port, using database at $dbpath"
    @info "Open the index.html file in the browser to connect to the server and start taking notes."
    server = HTTP.WebSockets.listen(messagehandler, host, port, check_origin=corshandler)
    # Code is blocking, so the server will keep running until it is shut down by a "shutdown" message or by interrupting the process.
end 


function __init__()
    @info "WSNotes.jl module loaded. Use WSNotes.run() to start the WebSocket server."
end 


end # module WSNotes
