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
end

