return function(level, source, message)
	vim.notify("[" .. source .. "] " .. message, level)
end
