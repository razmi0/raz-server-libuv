-- watch.js main.lua ./ 0.0.0.0 8080 --quiet

---@class ServerConfig
---@field host? string
---@field port? number

---@class Server
---@field _host string The host address to bind the server to
---@field _port number The port number to bind the server to
---@field _app App The application instance
---@field new fun(): Server  The server instance
---@field start fun(self: Server, app : App, base: table): nil Start the HTTP server and begin listening for connections

local uv = require('luv')
local inspect = require("inspect")

local Server = {}
Server.__index = Server
function Server.new()
    local instance = setmetatable({}, Server)
    instance._host = arg[1] or "127.0.0.1"
    instance._port = tonumber(arg[2]) or 0
    instance._server = uv.new_tcp()
    return instance
end

---@param app App
---@param server_config? ServerConfig
function Server:start(app, server_config)
    if server_config then
        self._host = server_config.host or self._host
        self._port = server_config.port or self._port
    end

    self._server:bind(self._host, self._port)

    self._server:listen(128, function(err)
        assert(not err, err)
        local client = uv.new_tcp()
        self._server:accept(client)

        local chunks = ""
        client:read_start(function(_err, chunk)
            assert(not _err, err)
            if chunk then
                chunks = chunks .. chunk
                local response = app:_run(chunks)
                client:write(response)
            else
                client:close()
            end
        end)
    end)

    print("\27[90m[Started]\27[0m \27[34m" .. "http://" .. self._host .. ":" .. self._port .. "\27[0m")

    uv.run()
end

return Server
