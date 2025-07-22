local Request = require("lib.request")
local Response = require("lib.response")
local Context = require("lib.context")
local Router = require("lib.router")
local compose = require("lib.compose")
local HTTP400 = require("lib.http-exception.bad-request")
local HTTP413 = require("lib.http-exception.content-too-large")
local HTTP500 = require("lib.http-exception.internal-server-error")

---@class AppConfig
---@field maxBodySize number

---@class App
---@field _router Router
---@field new fun():App
---@field use fun(self: App, middleware: function): App
---@field get fun(self: App, path: string, callback: function): App
---@field post fun(self: App, path: string, callback: function): App
---@field put fun(self: App, path: string, callback: function): App
---@field delete fun(self: App, path: string, callback: function): App
---@field all fun(self: App, path: string, callback: function): App
---@field _run fun(self: App, client: any): nil

local App = {}
App.__index = App

function App.new()
    local instance = setmetatable({}, App)
    instance._router = Router.new()
    return instance
end

function App:use(path, ...)
    self._router:add(nil, path, { ... })
    return self
end

function App:get(path, ...)
    self._router:add("GET", path, { ... })
    return self
end

function App:post(path, ...)
    self._router:add("POST", path, { ... })
    return self
end

function App:put(path, ...)
    self._router:add("PUT", path, { ... })
    return self
end

function App:delete(path, ...)
    self._router:add("DELETE", path, { ... })
    return self
end

function App:all(path, ...)
    for _, m in ipairs({ "POST", "GET", "PUT", "DELETE", "PATCH" }) do
        self._router:add(m, path, { ... })
    end
    return self
end

function App:on(methods, paths, ...)
    methods =
        type(methods) == "string" and { methods }
        or methods
        or { "POST", "GET", "PUT", "DELETE", "PATCH" }
    paths =
        type(paths) == "string" and { paths }
        or paths
        or { "/" }

    for _, m in ipairs(methods) do
        for _, p in ipairs(paths) do
            self._router:add(m, p, { ... })
        end
    end
end

---@param req Request The request object
---@param res Response The response object
function App:_run(req, res)
    local ctx = Context.new(req, res)
    if not ctx then ctx._err_handler = HTTP500 end

    local mws, params, match = self._router:match(req.method, req.path)
    req._params = params

    local ok, _ = pcall(function()
        compose(mws, ctx, match)
    end)

    if not ok or not ctx._finalized then
        return HTTP500(ctx):send()
    end

    return ctx.res:send()
end

return App
