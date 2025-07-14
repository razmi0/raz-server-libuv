local uv = require("luv")

local function await(callback)
    local co = coroutine.running()
    if not co then error("await() must be called inside a coroutine", 2) end

    local async = uv.new_async(function()
        local ok, result = pcall(callback)
        coroutine.resume(co, ok, result)
    end)

    async:send()
    return coroutine.yield()
end

local function async(main)
    coroutine.wrap(main)()
end

return async, await
