using Test, WSNotes
using HTTP, JSON 

# Before tests, start the server in a separate task 
@async WSNotes.run()

sleep(1)

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