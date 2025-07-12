local function setInterval(callback, interval)
    local timer = require("luv").new_timer()
    timer:start(interval, interval, function()
        callback()
    end)
    return timer
end

return setInterval
