-- Creating a simple setTimeout wrapper
local function setTimeout(timeout, callback)
    local timer = require("luv").new_timer()
    timer:start(timeout, 0, function()
        timer:stop()
        timer:close()
        callback()
    end)
    return timer
end

return setTimeout
