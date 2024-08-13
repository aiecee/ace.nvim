---@param file string
return function(file)
	local normalized_file = vim.fs.normalize(file)
	local log_file = io.open(normalized_file, "a+")

	local logger_augroup = vim.api.nvim_create_augroup("AceLogger", {})
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = logger_augroup,
		callback = function()
			if not log_file then
				return
			end
			log_file:flush()
			log_file:close()
		end,
	})

	return function(level, source, message)
		if not log_file then
			return
		end
		local formatted_time = os.date("%x %X")
		local log_item = vim.json.encode({
			time = formatted_time,
			level = level,
			source = source,
			message = message,
		})
		log_file:write(log_item .. "\n")
		log_file:flush()
	end
end
