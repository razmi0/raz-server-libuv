local inspect = require("inspect")

---@class RequestConfig
---@field maxBodySize? integer

---@class Request
---@field _chunks string The raw request string
---@field _headers table<string, string> The headers of the request
---@field _queries table<string, string> The queries of the request
---@field _params table<string, string> The parameters of the request
---@field method string The method of the request
---@field path string The path of the request
---@field query string The query of the request
---@field url string The url of the request
---@field protocol string The protocol of the request
---@field body string The body of the request
---@field hasBody boolean Whether the request has a body
---@field keepAlive boolean Whether the request is keep-alive
---@field maxBodySize integer The maximum body size
---@field new fun(chunks : string, config? : RequestConfig): Request Contructor
---@field _parse fun(self: Request): boolean Parse the request (heading, headers, body)
---@field _setMaxContentLength fun(self: Request, size: integer): Request Set the maximum body size
---@field header fun(self: Request, key: string): string|table Get a header value or all headers
---@field query fun(self: Request, key: string): string|table Get a query value or all queries
---@field param fun(self: Request, key: string): string|table Get a parameter value or all parameters
---@field parseBody fun(self: Request, type: string): Request Parse the request body according to the specified content type

local Request = {}
Request.__index = Request

local default_request = {
    _chunks = "",
    _headers = {},
    _queries = {},
    _params = {},
    url = "",
    query = "",
    method = nil,
    path = nil,
    protocol = nil,
    body = "",
    hasBody = false,
    keepAlive = false,
    maxBodySize = 1024 * 1024, -- 1MB
}

function Request.new(chunks, config)
    local instance = setmetatable({}, Request)
    for key, value in pairs(default_request) do
        instance[key] = value
    end
    instance._headers = {}
    for key, value in pairs(default_request._headers) do
        instance._headers[key] = value
    end
    instance._chunks = chunks
    instance.maxBodySize = config.maxBodySize or (1024 * 1024)
    return instance
end

--- Get a header value or all headers
---@param key string|nil
function Request:header(key)
    if not key then
        return self._headers
    end
    return self._headers[key]
end

--- Get a query value or all queries
---@param key string|nil
function Request:query(key)
    if not key then
        return self._queries
    end
    return self._queries[key]
end

--- Get a parameter value or all parameters
---@param key string|nil
function Request:param(key)
    if not key then
        return self._params
    end
    return self._params[key]
end

---@class RequestParseResult
---@field valid boolean
---@field errCode integer

---Parse the incoming request
---@private
---@return RequestParseResult
function Request:_parse()
    ---@vararg "body_split" | "request_line" | "headers" | "body" | "done"
    local state = ""

    local ok, result_or_err = pcall(function()
        -- Split head/body
        state = "body_split"
        local head, body = self._chunks:match("^(.-)\r\n\r\n(.*)")
        if not head or not body then
            error(400) -- Malformed request
        end

        local lines = {}
        for line in head:gmatch("[^\r\n]+") do
            lines[#lines + 1] = line
        end

        state = "request_line"
        local method, url, protocol = lines[1]:match("^(%S+)%s+(%S+)%s+(HTTP/%d%.%d)")
        if not method or not url or not protocol then
            error(400)
        end


        -- Parse query string
        state = "headers"
        local path, query_string = url:match("([^?]+)%??(.*)")
        local queryTable = {}
        for key, value in query_string:gmatch("([^=]+)=([^&]*)&?") do
            queryTable[key] = value
        end

        -- Parse headers
        for i = 2, #lines do
            local key, value = lines[i]:match("^(.-):%s*(.*)")
            if key and value then
                self._headers[key] = value
            end
        end

        self.method = method
        self.path = path
        self.protocol = protocol
        self.body = body
        self._queries = queryTable
        self.url = url

        local connection = self:header("Connection")
        if connection == "keep-alive" or (self.protocol == "HTTP/1.1" and connection ~= "close") then
            self.keepAlive = true
        end

        -- Body parsing with Content-Length
        state = "body"
        local contentLength = tonumber(self._headers["Content-Length"])
        if contentLength and contentLength > 0 then
            if contentLength > self.maxBodySize then
                error(413)
            end

            if #self.body >= contentLength then
                self.hasBody = true
                self.body = self.body:sub(1, contentLength)
            else
                error(400) -- Body too short
            end
        end

        return true
    end)

    if not ok then
        print("Error parsing at " .. state .. " code : " .. result_or_err)
        local code = tonumber(result_or_err)
        if code then
            return { valid = false, errCode = code }
        else
            return { valid = false, errCode = 400 } -- Unknown error fallback
        end
    end

    state = "done"

    print(inspect(self))

    return { valid = true, errCode = 0 }
end

return Request
