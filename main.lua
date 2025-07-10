local uv = require('luv')

local function create_server(host, port, on_connection)
    local server = uv.new_tcp()
    server:bind(host, port)
    server:listen(128, function(err)
        print("Client connection ...")
        assert(not err, err)
        local client = uv.new_tcp()
        server:accept(client)
        on_connection(client)
    end)
    return server
end

local server = create_server("127.0.0.1", 8080, function(client)
    local chunks = ""
    client:read_start(function(err, chunk)
        print("Client reading start ...")
        assert(not err, err)
        print("Client reading ...")
        if chunk then
            print("reading chunk ...")
            chunks = chunks .. chunk
            client:write("HTTP/1.1 200 OK\r\nContent-Length: 12\r\n\r\nHello World!")
        else
            print("no chunk to read ...")
            print(chunks)
            client:close()
        end
    end)
end)

print("TCP Echo server listening on port " .. "http://localhost:" .. server:getsockname().port)

uv.run()

--------------
