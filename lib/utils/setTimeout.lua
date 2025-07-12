-- Creating a simple setTimeout wrapper
local function setTimeout(callback, delay)
    local timer = require("luv").new_timer()
    timer:start(delay, 0, function()
        timer:stop()
        timer:close()
        callback()
    end)
    return timer
end

return setTimeout
