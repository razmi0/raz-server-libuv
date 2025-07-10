-----------------------------------
-----------------------------------
-----------------------------------

-- local http = require("http")

-- local function onRequest(req, res)
--     local body = "Hello world\n"
--     res:setHeader("Content-Type", "text/plain")
--     res:setHeader("Content-Length", #body)
--     res:finish(body)
-- end

-- http.createServer(onRequest):listen(8080)
-- print("Server listening at http://localhost:8080/")

-----------------------------------
-----------------------------------
-----------------------------------


-- This example just for learning the raw uv ways of making a echo server in luvit.
-- 'tcp-echo-server-simple.lua' is a much simpler version.

-- local uv = require('uv')

-- -- Create listener socket
-- local server = uv.new_tcp()
-- server:bind('127.0.0.1', 1234)

-- server:listen(128, function(err)
--     -- Create socket handle for client
--     local client = uv.new_tcp()

--     -- Accept incoming connection
--     server:accept(client)
--     print("Client connected")

--     -- Relay data back to client
--     client:read_start(function(err, data)
--         -- If error, print and close connection
--         if err then
--             print("Client read error: " .. err)
--             client:close()
--         end

--         -- If data is set the client has sent data, if unset the client has disconnected
--         if data then
--             print(data)
--             client:write(data)
--         else
--             print("Client disconnected")
--             client:close()
--         end
--     end)
-- end)


-----------------------------------
-----------------------------------
-----------------------------------

-- local timer = require 'timer'
-- local thread = require 'thread'

-- local interval = timer.setInterval(1000, function()
--     print('Main Thread', thread.self(), os.date())
-- end)

-- print("Main ...running...")

-- function entry(cli)
--     local timer = require 'timer'
--     local thread = require 'thread'
--     local interval = timer.setInterval(1000, function()
--         print(cli, thread.self(), os.date())
--     end)
-- end

-- thread.start(entry, 'cli1')
-- thread.start(entry, 'cli2')
-- thread.start(entry, 'cli3')


-----------------------------------
-----------------------------------
-----------------------------------


-- local uv = require('uv')
-- local Request = require("Request")
-- local Response = require("Response")
-- local Context = require("Context")

-- ---@class ServerConfig
-- ---@field host string
-- ---@field port number

-- ---@class Server
-- ---@field _host string The host address to bind the server to
-- ---@field _port number The port number to bind the server to
-- ---@field _app App The application instance
-- ---@field new fun(app : App): Server  The server instance
-- ---@field start fun(self: Server, base: table): nil Start the HTTP server and begin listening for connections

-- local Server = {}
-- Server.__index = Server

-- ---@param app App
-- function Server.new(app)
--     local instance = setmetatable({}, Server)
--     instance._host = "127.0.0.1"
--     instance._port = 8080
--     instance._app = app
--     return instance
-- end

-- -- Parses headers to find Content-Length
-- ---@param data string
-- ---@return number
-- local function get_content_length(data)
--     local content_length = data:match("Content%-Length:%s*(%d+)")
--     return tonumber(content_length) or 0
-- end

-- -- Reads the entire HTTP request asynchronously
-- ---@param client userdata uv_tcp_t handle
-- ---@param callback fun(err: string|nil, data: string|nil)
-- local function read_http_request(client, callback)
--     local timer = uv.new_timer()
--     local buffer = {}
--     local buffer_length = 0
--     local header_end_index = nil
--     local content_length = 0
--     local has_called_back = false

--     -- Timeout handler (5 seconds)
--     timer:start(5000, 0, function()
--         if not has_called_back then
--             has_called_back = true
--             timer:close()
--             client:read_stop()
--             client:close()
--             callback("timeout")
--         end
--     end)

--     -- Cleanup and callback helper
--     local function finish(err, data)
--         if has_called_back then return end
--         has_called_back = true
--         timer:close()
--         client:read_stop()
--         if not err then
--             callback(nil, data)
--         else
--             callback(err)
--         end
--     end

--     -- Read incoming data
--     client:read_start(
--         function(err, chunk)
--             if err then
--                 finish("read_error: " .. tostring(err))
--                 return
--             end

--             if not chunk then -- EOF
--                 if buffer_length > 0 then
--                     finish(nil, table.concat(buffer))
--                 else
--                     finish("eof")
--                 end
--                 return
--             end

--             -- Append chunk to buffer
--             table.insert(buffer, chunk)
--             buffer_length = buffer_length + #chunk
--             local accumulated = table.concat(buffer)

--             -- Locate end of headers if not found
--             if not header_end_index then
--                 header_end_index = accumulated:find("\r\n\r\n", 1, true)
--                 if header_end_index then
--                     content_length = get_content_length(accumulated:sub(1, header_end_index + 3))
--                 end
--             end

--             -- Check if we have the full request
--             if header_end_index then
--                 local total_expected = header_end_index + 3 + content_length
--                 if buffer_length >= total_expected then
--                     finish(nil, accumulated:sub(1, total_expected))
--                 end
--             end
--         end)
-- end

-- ---@param server_config? ServerConfig
-- function Server:start(server_config)
--     if server_config then
--         self._host = server_config.host or self._host
--         self._port = server_config.port or self._port
--     end

--     local server = uv.new_tcp()
--     server:bind(self._host, self._port)
--     server:listen(128, function(err)
--         if err then
--             print("Server listen error: " .. tostring(err))
--             return
--         end

--         local client = uv.new_tcp()
--         server:accept(client)
--         self:handle_connection(client)
--     end)

--     print("\27[90m[Started]\27[0m \27[34mhttp://" .. self._host .. ":" .. self._port .. "\27[0m")
-- end

-- -- Handles a new client connection
-- ---@param client userdata uv_tcp_t handle
-- function Server:handle_connection(client)
--     read_http_request(client, function(err, request_data)
--         if err then
--             client:close()
--             return
--         end

--         -- Process request and get response
--         local response = self._app:_run(request_data, client)

--         -- Write response and close connection
--         client:write(response, function(write_err)
--             if write_err then
--                 print("Write error: " .. tostring(write_err))
--             end
--             client:close()
--         end)
--     end)
-- end

-- local app = {
--     _run = function(raw_request, client)
--         -- Delegate parsing to Request class

--         local req = Request.new(raw_request)
--         local res = Response.new(client) -- Pass client for potential streaming
--         local ctx = Context.new(req, res)

--         -- Validate request parsing
--         if not req or not res or not ctx then
--             return "HTTP/1.1 500 InternalServerError\r\nContent-Length: 0\r\n\r"
--         end
--         if not req:_parse() then
--             return "HTTP/1.1 400 BadRequest\r\nContent-Length: 0\r\n\r"
--         end

--         return "HTTP/1.1 200 OK\r\nContent-Length: 12\r\n\r\nHello World!"
--     end
-- }

-- Server.new(app):start()
