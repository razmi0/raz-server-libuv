local server = require("lib/server")
local app = require("lib/app").new()

app:all("*", function(c)
    return c:html("<h1>Hello World</h1>")
end)

server.new():start(app, {
    port = 8080,
})
