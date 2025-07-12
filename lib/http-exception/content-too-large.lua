function HTTP413(ctx)
    ctx.res:setContentType("text/plain")
    ctx.res:setStatus(413)
    ctx.res:setBody("413 Content Too Large")
    return ctx.res
end

return HTTP413
