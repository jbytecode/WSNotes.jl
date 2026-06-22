using Test, WSNotes
using HTTP, JSON 

# Before tests, start the server in a separate task 
@async WSNotes.run()

sleep(2)

@testset "Ping Test" begin 
    url = "ws://localhost:8000"
    ws = HTTP.WebSockets.open(url)
    HTTP.WebSockets.send(ws, JSON.json(Dict("type" => "ping")))
    response = HTTP.WebSockets.receive(ws)
    parsedresponse = JSON.parse(response)
    @test parsedresponse["type"] == "pong"
    HTTP.WebSockets.close(ws)
end 

@testset "Unknown Message Type Test" begin 
    url = "ws://localhost:8000"
    ws = HTTP.WebSockets.open(url)
    HTTP.WebSockets.send(ws, JSON.json(Dict("type" => "unknown")))
    response = HTTP.WebSockets.receive(ws)
    parsedresponse = JSON.parse(response)
    @test parsedresponse["type"] == "error"
    @test occursin("unknown message type", parsedresponse["message"])
    HTTP.WebSockets.close(ws)
end

@testset "Add Note Test" begin 
    url = "ws://localhost:8000"
    ws = HTTP.WebSockets.open(url)
    datetime = "2024-06-01T12:00:00"
    subject = "Test Note"
    content = "This is a test note."
    HTTP.WebSockets.send(ws, JSON.json(Dict("type" => "addnote", "datetime" => datetime, "subject" => subject, "content" => content)))
    response = HTTP.WebSockets.receive(ws)
    parsedresponse = JSON.parse(response)
    @test parsedresponse["type"] == "addnote_response"
    @test haskey(parsedresponse, "id")
    HTTP.WebSockets.close(ws)
end

@testset "Get Note Test" begin    
    id = 1
    url = "ws://localhost:8000"
    ws = HTTP.WebSockets.open(url)
    HTTP.WebSockets.send(ws, JSON.json(Dict("type" => "getnote", "id" => id)))
    response = HTTP.WebSockets.receive(ws)
    parsedresponse = JSON.parse(response)
    @test parsedresponse["type"] == "getnote_response"
    @test haskey(parsedresponse, "note")
    note = parsedresponse["note"]
    @test note["id"] == id
    @test note["subject"] == "Test Note"
    @test note["content"] == "This is a test note."
    HTTP.WebSockets.close(ws)
end

@testset "Get Notes Test" begin 
    url = "ws://localhost:8000"
    ws = HTTP.WebSockets.open(url)
    HTTP.WebSockets.send(ws, JSON.json(Dict("type" => "getnotes")))
    response = HTTP.WebSockets.receive(ws)
    parsedresponse = JSON.parse(response)
    @test parsedresponse["type"] == "getnotes_response"
    @test haskey(parsedresponse, "notes")
    notes = parsedresponse["notes"]
    @test notes isa Vector
    @test length(notes) >= 1
    HTTP.WebSockets.close(ws)
end

@testset "Update note" begin 
    url = "ws://localhost:8000"
    ws = HTTP.WebSockets.open(url)
    # Insert new 
    datetime = "2024-06-01T12:00:00"
    subject = "Note to Update"
    content = "This note will be updated."
    HTTP.WebSockets.send(ws, JSON.json(Dict("type" => "addnote", "datetime" => datetime, "subject" => subject, "content" => content)))
    response = HTTP.WebSockets.receive(ws)
    parsedresponse = JSON.parse(response)
    @test parsedresponse["type"] == "addnote_response"
    id = parsedresponse["id"]

    # Update the note
    new_subject = "Updated Note"
    new_content = "This note has been updated."
    HTTP.WebSockets.send(ws, JSON.json(Dict("type" => "updatenote", "id" => id, "datetime" => datetime, "subject" => new_subject, "content" => new_content)))
    response = HTTP.WebSockets.receive(ws)
    parsedresponse = JSON.parse(response)
    @test parsedresponse["type"] == "updatenote_response"
    @test parsedresponse["id"] == id
    @test parsedresponse["subject"] == new_subject
    @test parsedresponse["content"] == new_content  
    HTTP.WebSockets.close(ws)
end 

@testset "Delete note" begin 
    url = "ws://localhost:8000"
    ws = HTTP.WebSockets.open(url)
    # Insert new 
    datetime = "2024-06-01T12:00:00"
    subject = "Note to Delete"
    content = "This note will be deleted."
    HTTP.WebSockets.send(ws, JSON.json(Dict("type" => "addnote", "datetime" => datetime, "subject" => subject, "content" => content)))
    response = HTTP.WebSockets.receive(ws)
    parsedresponse = JSON.parse(response)
    @test parsedresponse["type"] == "addnote_response"
    id = parsedresponse["id"]

    # Delete the note
    HTTP.WebSockets.send(ws, JSON.json(Dict("type" => "deletenote", "id" => id)))
    response = HTTP.WebSockets.receive(ws)
    parsedresponse = JSON.parse(response)
    @test parsedresponse["type"] == "deletenote_response"
    @test parsedresponse["id"] == id

    # Try to get the deleted note
    HTTP.WebSockets.send(ws, JSON.json(Dict("type" => "getnote", "id" => id)))
    response = HTTP.WebSockets.receive(ws)
    parsedresponse = JSON.parse(response)
    @test parsedresponse["type"] == "error"
    @test occursin("not found", parsedresponse["message"])
    
    HTTP.WebSockets.close(ws)
end 

@testset "Search keyword test" begin 
    url = "ws://localhost:8000"
    ws = HTTP.WebSockets.open(url)
    # Insert new 
    datetime = "2024-06-01T12:00:00"
    subject = "Searchable Note"
    content = "This note contains a unique keyword: foobar."
    HTTP.WebSockets.send(ws, JSON.json(Dict("type" => "addnote", "datetime" => datetime, "subject" => subject, "content" => content)))
    response = HTTP.WebSockets.receive(ws)
    parsedresponse = JSON.parse(response)
    @test parsedresponse["type"] == "addnote_response"
    id = parsedresponse["id"]

    # Search for the keyword
    keyword = "foobar"
    HTTP.WebSockets.send(ws, JSON.json(Dict("type" => "search", "keyword" => keyword)))
    response = HTTP.WebSockets.receive(ws)
    parsedresponse = JSON.parse(response)
    @test parsedresponse["type"] == "search_response"
    @test haskey(parsedresponse, "notes")
    notes = parsedresponse["notes"]
    @test any(note -> note["id"] == id, notes)

    HTTP.WebSockets.close(ws)
end 