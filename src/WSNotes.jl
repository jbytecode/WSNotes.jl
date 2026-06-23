module WSNotes


using SQLite, HTTP, JSON 


include("DB.jl")
import .DB

abstract type MessageType end 
struct Ping <: MessageType end
struct Shutdown <: MessageType end
struct AddNote <: MessageType end
struct UpdateNote <: MessageType end
struct DeleteNote <: MessageType end
struct GetNote <: MessageType end
struct GetNotes <: MessageType end
struct SearchNotes <: MessageType end
struct UnknownMessage <: MessageType end


export run, HTTP

function handle(::Type{Ping}, ws)
    try
        retmessage = JSON.json(Dict("type" => "pong"))
        HTTP.WebSockets.send(ws, retmessage)
    catch e
        @error "Error handling Ping message: $e"
    end
end

function handle(::Type{Shutdown}, ws)
    try
        @info "Shutdown message received. Closing WebSocket connection and shutting down the server..."
        HTTP.WebSockets.close(ws)
        exit(0)
    catch e
        @error "Error handling Shutdown message: $e"
    end
end

function handle(::Type{AddNote}, ws, db, parsedmessage)
    try
        datetime = get(parsedmessage, "datetime", "")
        subject = get(parsedmessage, "subject", "")
        content = get(parsedmessage, "content", "")
        id = DB.addnote(db, datetime, subject, content)
        retmessage = JSON.json(Dict("type" => "addnote_response", "id" => id))
        HTTP.WebSockets.send(ws, retmessage)
    catch e
        @error "Error handling AddNote message: $e"
    end
end

function handle(::Type{UpdateNote}, ws, db, parsedmessage)
    try
        id = parse(Int64, parsedmessage["id"])
        datetime = get(parsedmessage, "datetime", "")
        subject = get(parsedmessage, "subject", "")
        content = get(parsedmessage, "content", "")
        DB.updatenote(db, id, datetime, subject, content)
        retmessage = JSON.json(Dict("type" => "updatenote_response", "id" => id, "datetime" => datetime, "subject" => subject, "content" => content))
        HTTP.WebSockets.send(ws, retmessage)
    catch e
        @error "Error handling UpdateNote message: $e"
    end
end

function handle(::Type{DeleteNote}, ws, db, parsedmessage)
    try
        id = parse(Int64, parsedmessage["id"])
        DB.deletenote(db, id)
        retmessage = JSON.json(Dict("type" => "deletenote_response", "id" => id))
        HTTP.WebSockets.send(ws, retmessage)
    catch e
        @error "Error handling DeleteNote message: $e"
    end
end

function handle(::Type{GetNote}, ws, db, parsedmessage)
    try
        id = parse(Int64, parsedmessage["id"])
        note = DB.getnote(db, id)
        if isnothing(note)
            retmessage = JSON.json(Dict("type" => "error", "message" => "note with id $id not found"))
        else
            retmessage = JSON.json(Dict("type" => "getnote_response", "note" => Dict("id" => note.id, "datetime" => note.datetime, "subject" => note.subject, "content" => note.content)))
        end
        HTTP.WebSockets.send(ws, retmessage)
    catch e
        @error "Error handling GetNote message: $e"
    end
end

function handle(::Type{GetNotes}, ws, db)
    try
        notes = DB.getnotes(db)
        noteslist = [Dict("id" => note.id, "datetime" => note.datetime, "subject" => note.subject, "content" => note.content) for note in notes]
        retmessage = JSON.json(Dict("type" => "getnotes_response", "notes" => noteslist))
        HTTP.WebSockets.send(ws, retmessage)
    catch e
        @error "Error handling GetNotes message: $e"
    end
end

function handle(::Type{SearchNotes}, ws, db, parsedmessage)
    try
        query = get(parsedmessage, "keyword", "")
        notes = DB.searchkeyword(db, query)
        noteslist = [Dict("id" => note.id, "datetime" => note.datetime, "subject" => note.subject, "content" => note.content) for note in notes]
        retmessage = JSON.json(Dict("type" => "searchnotes_response", "notes" => noteslist))
        HTTP.WebSockets.send(ws, retmessage)
    catch e
        @error "Error handling SearchNotes message: $e"
    end
end

function handle(::Type{UnknownMessage}, ws, messagetype)
    try
        retmessage = JSON.json(Dict("type" => "error", "message" => "unknown message type $messagetype"))
        HTTP.WebSockets.send(ws, retmessage)
    catch e
        @error "Error handling UnknownMessage: $e"
    end
end

function run(; host::String="localhost", port::Int=8000, dbpath::String="notes.db")

    corshandler(request, client) = true 

    function messagehandler(ws)
        for rawmessage in ws
            jsonmessage = rawmessage isa AbstractString ? rawmessage : String(rawmessage)
            parsedmessage = JSON.parse(jsonmessage)
            type = get(parsedmessage, "type", nothing)
            if type == "ping"
                handle(Ping, ws)
            elseif type == "shutdown"
                handle(Shutdown, ws)
            elseif type == "addnote"
                handle(AddNote, ws, db, parsedmessage)
            elseif type == "updatenote"
                handle(UpdateNote, ws, db, parsedmessage)
            elseif type == "deletenote"
                handle(DeleteNote, ws, db, parsedmessage)
            elseif type == "getnote"
                handle(GetNote, ws, db, parsedmessage)
            elseif type == "getnotes"
                handle(GetNotes, ws, db)
            elseif type == "searchnotes"
                handle(SearchNotes, ws, db, parsedmessage)
            else 
                handle(UnknownMessage, ws, type)
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
