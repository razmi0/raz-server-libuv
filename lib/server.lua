-- uv.write(stream, data, [callback])
-- method form stream:write(data, [callback])

-- Parameters:

-- stream: userdata for sub-type of uv_stream_t
-- data: buffer
-- callback: callable or nil
-- err: nil or string
-- Write data to stream.

-- data can either be a Lua string or a table of strings. If a table is passed in, the C backend will use writev to send all strings in a single system call.

-- The optional callback is for knowing when the write is complete.

-- watch.js main.lua ./ 0.0.0.0 8080 --quiet
-- wrk -t10 -c100 -d10s -L http://localhost:8080

---@class ServerConfig
---@field host? string
---@field port? number

---@class Server
---@field _host string The host address to bind the server to
---@field _port number The port number to bind the server to
---@field _app App The application instance
---@field _server userdata The server instance
---@field _clients table The clients connected to the server
---@field new fun(): Server  The server instance
---@field start fun(self: Server, app : App, base: table): nil Start the HTTP server and begin listening for connections

local inspect       = require("inspect")
local uv            = require('luv')
local Request       = require("lib/request")
local Response      = require("lib/response")
local _, HTTP400raw = require("lib/http-exception/bad-request")
local _, HTTP413raw = require("lib/http-exception/content-too-large")
local _, HTTP500raw = require("lib/http-exception/internal-server-error")

local errResponses  = {
    [400] = HTTP400raw,
    [413] = HTTP413raw,
    [500] = HTTP500raw,
}

local function logError(stage, err)
    print(string.format("\27[38;5;208m[Outbound Error][%s]\27[0m : %s", stage, tostring(err)))
end

local Server = {}
Server.__index = Server

function Server.new()
    local self = setmetatable({}, Server)
    self._host = arg[1] or "127.0.0.1"
    self._port = tonumber(arg[2]) or 0
    self._server = uv.new_tcp()
    self._clients = {}
    self._config = {
        maxBodySize = 1024 * 1024 * 10, -- 10MB
    }
    return self
end

function Server:start(app, config)
    self._config = config or self._config
    self._host = config and config.host or self._host
    self._port = config and config.port or self._port

    self._server:bind(self._host, self._port)

    self._server:listen(1024, function(err)
        if err then
            logError("LISTEN", err)
            return
        end

        local client = self:_accept()
        if client then
            self:_handleClient(app, client)
        end
    end)

    print(string.format("\27[90m[Started]\27[0m \27[34mhttp://%s:%d\27[0m", self._host, self._port))
    uv.run()
end

function Server:_accept()
    local client = uv.new_tcp()
    local ok, err = pcall(function()
        self._server:accept(client)
    end)

    if not ok then
        logError("ACCEPT", err)
        client:close()
        return nil
    end

    local id = tostring(client)
    self._clients[id] = client
    return client
end

function Server:_removeClient(client)
    local id = tostring(client)
    if self._clients[id] then
        self._clients[id] = nil
        client:close()
    end
end

function Server:_handleClient(app, client)
    local buffer = ""

    client:read_start(
        function(rErr, chunk)
            if rErr then
                logError("READ", rErr)
                self:_removeClient(client)
                return
            end

            if not chunk then
                self:_removeClient(client)
                return
            end

            buffer = buffer .. chunk

            -- buffer parsing tentative
            local parsed
            local req
            local ok, _ = pcall(
                function()
                    req = Request.new(buffer, {
                        maxBodySize = self._config.maxBodySize,
                    })
                    parsed = req:_parse()
                end
            )


            -- malformed or incomplete
            if not ok or not parsed or not parsed.valid then
                if parsed and parsed.errCode == 400 then
                    return -- incomplete
                else
                    client:write(HTTP400raw, function() self:_removeClient(client) end)
                    return -- malformed
                end
            end

            -- complete and valid
            local res = Response.new(req)
            res.keepAlive = req.keepAlive
            local response = app:_run(req, res)

            client:write(response,
                function(wErr)
                    if wErr then
                        logError("WRITE", wErr)
                        self:_removeClient(client)
                        return
                    end

                    if not req.keepAlive then
                        self:_removeClient(client)
                    else
                        buffer = ""
                    end
                end
            )
        end
    )
end

return Server
