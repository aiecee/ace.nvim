local Logger = require("ace.shared.logger")
local file_sink = require("ace.shared.logger.file_sink")
local notify_sink = require("ace.shared.logger.notify_sink")

local Events = require("ace.shared.events")

local build_config = require("ace.shared.build_config")

local encode = vim.base64.encode

---@class SessionsConfig
---@field autosave boolean
---@field default_filename string
---@field storage_dir string
---@field log_file string | nil

---@class PartialSessionsConfig
---@field autosave? boolean
---@field default_filename? string
---@field storage_dir? string
---@field log_file? string

---@type SessionsConfig
local default_config = {
	autosave = true,
	default_filename = "session.vim",
	---@diagnostic disable-next-line: param-type-mismatch
	storage_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "ace", "sessions"),
	log_file = nil,
}

---@class Sessions
---@field private config SessionsConfig
---@field private logger Logger
---@field events Events
local Sessions = {}

Sessions.__index = Sessions

---@return Sessions
function Sessions:new()
	return setmetatable({
		config = default_config,
		logger = Logger:new("AceSessions", { notify_sink }),
		events = Events:new("AceSessions"),
	}, self)
end

---@param file? string
function Sessions:save(file)
	file = file or self.config.default_filename
	local encoded_cwd = encode(vim.fn.getcwd())
	local session_dir = vim.fs.joinpath(self.config.storage_dir, encoded_cwd)
	vim.fn.mkdir(session_dir, "p")
	local target_path = vim.fs.joinpath(session_dir, file)

	self.events:emit("SessionSavePre")
	vim.cmd("mksession! " .. target_path)
	self.events:emit("SessionSavePost")
end

---@param file? string
function Sessions:load(file)
	file = file or self.config.default_filename
	local encoded_cwd = encode(vim.fn.getcwd())
	local target_path = vim.fs.joinpath(self.config.storage_dir, encoded_cwd, file)

	if vim.fn.filereadable(target_path) ~= 0 then
		self.events:emit("SessionLoadPre")
		vim.cmd("silent! source " .. target_path)
		self.events:emit("SessionLoadPost")
	else
		self.logger:error("Unable to open session file: " .. target_path)
	end
end

---@return string[]
function Sessions:list()
	local encoded_cwd = encode(vim.fn.getcwd())
	local target_path = vim.fs.joinpath(self.config.storage_dir, encoded_cwd, "*.vim")
	local files = vim.fn.glob(target_path, true, true)
	return vim.iter(files)
		:map(function(file)
			return vim.fs.basename(file)
		end)
		:totable()
end

local sessions = Sessions:new()

---@param self Sessions
---@param partial_config PartialSessionsConfig
---@return Sessions
function Sessions.setup(self, partial_config)
	if self ~= sessions then
		---@diagnostic disable-next-line: cast-local-type
		partial_config = self
		self = sessions
	end

	self.config = build_config(default_config, partial_config)

	if self.config.log_file then
		self.logger = Logger:new("AceSessions", { notify_sink, file_sink(self.config.log_file) })
	end

	if self.config.autosave then
		vim.api.nvim_create_autocmd("VimLeavePre", {
			callback = function()
				self:save()
			end,
		})
	end

	return self
end

return sessions
