-- Debug: Trace ALL events after startup
local start = vim.uv.hrtime()
local logged_events = {}

local function log(msg)
	local elapsed = (vim.uv.hrtime() - start) / 1e6
	local line = string.format("[%.0fms] %s", elapsed, msg)
	print(line)
	-- Also write to file
	local f = io.open("/tmp/nvim-debug.log", "a")
	if f then
		f:write(line .. "\n")
		f:close()
	end
end

-- Clear debug log at start
local f = io.open("/tmp/nvim-debug.log", "w")
if f then
	f:close()
end

log("=== Debug started ===")

-- Log ALL autocommands that fire
local events_to_watch = {
	"VimEnter",
	"UIEnter",
	"BufEnter",
	"BufWinEnter",
	"FileType",
	"CursorMoved",
	"CursorHold",
	"InsertEnter",
	"LspAttach",
	"User",
}

for _, event in ipairs(events_to_watch) do
	vim.api.nvim_create_autocmd(event, {
		callback = function(args)
			local key = event .. ":" .. (args.match or "")
			if not logged_events[key] then
				log(string.format("Event: %s (match=%s, buf=%s)", event, args.match or "nil", args.buf or "nil"))
				logged_events[key] = true
			end
		end,
	})
end

-- Log when plugins load
local original_require = require
_G.require = function(modname)
	if modname:match("^mini%.") or modname:match("^snacks") or modname:match("copilot") then
		log("Loading module: " .. modname)
	end
	return original_require(modname)
end

-- Check event loop responsiveness
vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		log(">>> VimEnter fired - starting checks")

		-- Check every 100ms
		for i = 1, 100 do
			vim.defer_fn(function()
				log(string.format("Tick %d (%.1fs)", i, i * 0.1))
			end, i * 100)
		end
	end,
})

-- Track when input becomes responsive (only in log file)
local input_logged = false
vim.on_key(function(key)
	if not input_logged then
		-- Only write to file, don't print to screen
		local f = io.open("/tmp/nvim-debug.log", "a")
		if f then
			local elapsed = (vim.uv.hrtime() - start) / 1e6
			f:write(string.format("[%.0fms] >>> FIRST KEY PRESSED: %q\n", elapsed, key))
			f:close()
		end
		input_logged = true
	end
end, vim.api.nvim_create_namespace("debug_first_key"))
