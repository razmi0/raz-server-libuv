function HTTP400(ctx)
    ctx.res:setContentType("text/plain")
    ctx.res:setStatus(400)
    ctx.res:setBody("400 Bad Request")
    return ctx.res
end

local raw = "HTTP/1.1 400 Bad Request\r\nContent-Type: text/plain\r\nContent-Length: 15\r\n\r\n400 Bad Request\r\n"

return HTTP400, raw
