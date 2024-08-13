---@alias LoggerSink fun(level: integer, source: string, message: string)

---@class Logger
---@field private sinks LoggerSink[]
---@field private source string
local Logger = {}

Logger.__index = Logger

---@param source string
---@param sinks LoggerSink[]
---@return Logger
function Logger:new(source, sinks)
	return setmetatable({
		source = source,
		sinks = sinks,
	}, self)
end

---@param level integer one of |vim.log.levels|
---@param message string
function Logger:log(level, message)
	for _, sink in ipairs(self.sinks) do
		sink(level, self.source, message)
	end
end

---@param message string
function Logger:debug(message)
	self:log(vim.log.levels.DEBUG, message)
end

---@param message string
function Logger:info(message)
	self:log(vim.log.levels.INFO, message)
end

---@param message string
function Logger:warn(message)
	self:log(vim.log.levels.WARN, message)
end

---@param message string
function Logger:error(message)
	self:log(vim.log.levels.ERROR, message)
end

return Logger
