-- Debug: Find what's blocking after UI loads
local start = vim.uv.hrtime()

local function log(msg)
	local elapsed = (vim.uv.hrtime() - start) / 1e6
	print(string.format("[%.0fms] %s", elapsed, msg))
end

vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		log("VimEnter fired")

		-- Start profiling right after VimEnter
		vim.cmd("profile start /tmp/nvim-profile.log")
		vim.cmd("profile func *")
		vim.cmd("profile file *")

		-- Check periodically
		for i = 1, 10 do
			vim.defer_fn(function()
				log(string.format("Still running... (%ds)", i))
			end, i * 1000)
		end

		-- Stop profiling after 10 seconds
		vim.defer_fn(function()
			vim.cmd("profile stop")
			log("Profile saved to /tmp/nvim-profile.log")
		end, 10000)
	end,
})

-- Log when dashboard loads
vim.api.nvim_create_autocmd("FileType", {
	pattern = "snacks_dashboard",
	callback = function()
		log("Dashboard FileType set")
	end,
})

-- Log first input
vim.on_key(function()
	log("First key pressed - input working!")
	return nil
end, vim.api.nvim_create_namespace("debug_first_key"))
