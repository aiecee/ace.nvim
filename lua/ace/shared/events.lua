---@class Events a neat little wrapper around neovims autocmds
---@field private group_id integer
local Events = {}

Events.__index = Events

---@param group string
---@return Events
function Events:new(group)
	local group_id = vim.api.nvim_create_augroup(group, {})
	return setmetatable({
		group_id = group_id,
	}, self)
end

---@param event string
---@param callback function
---@return integer event id
function Events:on(event, callback)
	return vim.api.nvim_create_autocmd("User", {
		pattern = event,
		group = self.group_id,
		callback = callback,
	})
end

---@param event string
---@param callback function
---@return integer event id
function Events:once(event, callback)
	return vim.api.nvim_create_autocmd("User", {
		pattern = event,
		group = self.group_id,
		callback = callback,
		once = true,
	})
end

---@param event_id integer
function Events:off(event_id)
	vim.api.nvim_del_autocmd(event_id)
end

---@param event string
---@param data any
function Events:emit(event, data)
	vim.api.nvim_exec_autocmds("User", {
		pattern = event,
		group = self.group_id,
		data = data,
	})
end

return Events
