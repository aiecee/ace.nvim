return function(default_config, config)
	local final_config = vim.tbl_deep_extend("force", default_config, config or {})
	return final_config
end
