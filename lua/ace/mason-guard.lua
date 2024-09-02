local Logger = require("ace.shared.logger")
local notify_sink = require("ace.shared.logger.notify_sink")
local build_config = require("ace.shared.build_config")

local registry = require("mason-registry")
local Optional = require("mason-core.optional")

---@return string[]
local function get_tools()
	local formatter_specs = require("guard-collection.formatter")
	local formatters = vim.tbl_keys(formatter_specs)
	local linter_specs = require("guard-collection.linter")
	local linters = vim.tbl_keys(linter_specs)
	local tools = vim.tbl_extend("keep", formatters, linters)

	return vim.iter(registry.get_all_package_names())
		:filter(function(item)
			return vim.list_contains(tools, item)
		end)
		:totable()
end

---@param tool_name string
local function resolve_package(tool_name)
	return Optional.of_nilable(tool_name):map(function(package_name)
		if not registry.has_package(package_name) then
			return nil
		end
		local ok, pkg = pcall(registry.get_package, package_name)
		if ok then
			return pkg
		end
	end)
end

---@param logger Logger
---@param tools string[]
local function install(logger, tools)
	local Package = require("mason-core.package")
	for _, tool in ipairs(tools) do
		local tool_name, version = Package.Parse(tool)
		resolve_package(tool_name):if_present(
			---@param pkg Package
			function(pkg)
				if not pkg:is_installed() then
					pkg:install({ version = version }):once(
						"closed",
						vim.schedule_wrap(function()
							if pkg:is_installed() then
								logger:info(("%s was installed"):format(pkg.name))
							else
								logger:error(
									("Failed to install %s. Installation logs are available in :Mason and :MasonLog"):format(
										pkg.name
									)
								)
							end
						end)
					)
				end
			end
		)
	end
end

---@class MasonGuardConfig
---@field ensure_installed string[]

---@type MasonGuardConfig
local default_config = {
	ensure_installed = {},
}

local M = {}

---@param config MasonGuardConfig?
function M.setup(config)
	local log = Logger:new("AceMasonGuard", { notify_sink })
	local built_config = build_config(default_config, config)

	local tools_to_install = {}
	local tools = get_tools()

	for _, tool in ipairs(built_config.ensure_installed) do
		if vim.list_contains(tools, tool) then
			table.insert(tools_to_install, tool)
		else
			log:error(("Tool %q is not available to guard.nvim"):format(tool))
		end
	end

	install(log, tools_to_install)
end

return M
