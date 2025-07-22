local server = require("lib/server")
local app = require("lib/app").new()
local logger = require("lib/middleware/logger")
local JSON = require("cjson")
local HTTP400 = require("lib/http-exception/bad-request")
local uv = require("luv")
local static = require("lib.middleware.static")

local posts = {}

-- app:use("/*", logger())

-- app:on("GET", { "/", "/:file{^.+%.%w+}" }, static(function(c)
--     return {
--         root = "public",
--         path = c.req:param("file") or "index.html"
--     }
-- end)
-- )

app:post("/post", function(c)
    if not c.req.hasBody then return HTTP400(c) end
    local body = JSON.decode(c.req.body)

    posts[#posts + 1] = {
        id = #posts + 1,
        author = body.author,
        content = body.content,
    }

    -- Return a success response
    return c:json({
        message = "Post added successfully",
        post = body,
    })
end)

app:get("/post", function(c)
    return c:json(posts)
end)


app:get("/post/:id", function(c)
    local id = tonumber(c.req:param("id"))
    local post = posts[id]
    if not post then
        return c:json({ message = "Post " .. tostring(id) .. " not found" }, 404)
    end
    return c:json(post)
end)

-- app:get("/slow", function(c)
--     uv.timer_start(uv.new_timer(), 1000, 0, function()
--         return c:text("slow response")
--     end)
-- end)

app:get("/", function(c)
    return c:text("server is running")
end)

server.new():start(app, {
    port = 8080,
})
