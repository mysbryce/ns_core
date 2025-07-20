--- @meta

--- @class NS.Server
--- @field event NS.Server.Event

--- @class NS.Server.Event
--- @field register fun(self: NS.Server.Event, name: string, handler: fun(...),isNet: boolean?)
--- @field use fun(self: NS.Server.Event, mounted: string): fun(name: string, handler: fun(...), isNet: boolean?)
