---@class Request
---@field _raw_request string The raw request string
---@field _headers table<string, string> The headers of the request
---@field _queries table<string, string> The queries of the request
---@field _params table<string, string> The parameters of the request
---@field method string The method of the request
---@field path string The path of the request
---@field protocol string The protocol of the request
---@field body string The body of the request
---@field hasBody boolean Whether the request has a body
---@field bodyType string The type of the body
---@field bodyParsed boolean Whether the body has been parsed
---@field new fun(client : unknown): Request Contructor
---@field _parse fun(self: Request): boolean Parse the request (heading, headers, body)
---@field header fun(self: Request, key: string): string|table Get a header value or all headers
---@field query fun(self: Request, key: string): string|table Get a query value or all queries
---@field param fun(self: Request, key: string): string|table Get a parameter value or all parameters
---@field parseBody fun(self: Request, type: string): Request Parse the request body according to the specified content type

local Request = {}
Request.__index = Request

local default_request = {
    _headers = {},
    _queries = {},
    _params = {},
    method = nil,
    path = nil,
    protocol = nil,
    body = "",
    hasBody = false,
    bodyType = nil,
    bodyParsed = false,
    keepAlive = false,
}

function Request.new(raw_request)
    local instance = setmetatable({}, Request)
    for key, value in pairs(default_request) do
        instance[key] = value
    end
    instance._headers = {}
    for key, value in pairs(default_request._headers) do
        instance._headers[key] = value
    end
    if raw_request then
        instance._raw_request = raw_request
    else
        error("Request Empty")
    end
    return instance
end

--- Get a header value or all headers
function Request:header(key)
    if not key then
        return self._headers
    end
    return self._headers[key]
end

--- Get a query value or all queries
function Request:query(key)
    if not key then
        return self._queries
    end
    return self._queries[key]
end

--- Get a parameter value or all parameters
function Request:param(key)
    if not key then
        return self._params
    end
    return self._params[key]
end

--- Unfinished
--- Parse the request body according to the specified content type
function Request:parseBody(type)
    local bodyType = {
        expected = self._headers["Content-Type"],
        asked = type
    }

    if bodyType.expected ~= bodyType.asked then
        print("Parsing body as " .. bodyType.asked .. " but expected " .. bodyType.expected)
    end

    return self
end

local Request = {}
Request.__index = Request

function Request.new(raw_request)
    local self = setmetatable({}, Request)
    self._raw_request = raw_request
    self._headers = {}
    return self
end

---Parse the incoming request from raw data
---@private
function Request:_parse()
    -- Split the raw request into lines
    local lines = {}
    for line in self._raw_request:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end

    -- Extract method, path, and protocol from first line
    if #lines < 1 then return false end
    local headingLine = lines[1]
    local method, url, protocol = headingLine:match("(%S+)%s+(%S+)%s+(%S+)")
    if not method or not url or not protocol then
        return false
    end

    -- Parse path and query parameters
    local path, query_string = url:match("([^?]+)%??(.*)")
    local queryTable = {}
    for key, value in query_string:gmatch("([^=]+)=([^&]+)&?") do
        queryTable[key] = value
    end

    self.method = method
    self.path = path
    self.protocol = protocol
    self._queries = queryTable

    -- Parse headers
    local i = 2
    while i <= #lines do
        local headerLine = lines[i]
        if headerLine == "" then break end -- Empty line indicates end of headers

        local key, value = headerLine:match("([^:]+):%s*(.+)")
        if key then
            self._headers[key] = value
        end
        i = i + 1
    end

    -- Parse body if exists
    self.hasBody = false
    local contentLength = tonumber(self._headers["Content-Length"]) or 0
    if contentLength > 0 then
        -- Extract body by joining remaining lines
        local body_lines = {}
        for j = i, #lines do
            table.insert(body_lines, lines[j])
        end
        local body = table.concat(body_lines, "\r\n")

        -- Validate body length
        if #body >= contentLength then
            self.body = body:sub(1, contentLength)
            self.hasBody = true
        else
            return false
        end
    end

    self.bodyParsed = true
    return true
end

return Request
