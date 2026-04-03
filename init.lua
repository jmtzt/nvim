vim.loader.enable()

_G.Config = {}

local config_group = vim.api.nvim_create_augroup("custom-config", {})

local function github_url(repo)
	if repo:match("^https?://") then
		return repo
	end

	return "https://github.com/" .. repo
end

local function safely(fn)
	local ok, err = xpcall(fn, debug.traceback)
	if ok then
		return
	end

	vim.schedule(function()
		vim.notify(err, vim.log.levels.ERROR)
	end)
end

_G.Config.github_url = github_url

_G.Config.new_autocmd = function(event, pattern, callback, desc)
	local opts = { group = config_group, callback = callback, desc = desc }
	if pattern ~= nil then
		opts.pattern = pattern
	end

	vim.api.nvim_create_autocmd(event, opts)
end

_G.Config.pack_add = function(specs, opts)
	if type(specs) == "string" then
		specs = { specs }
	elseif not vim.islist(specs) then
		specs = { specs }
	end

	local normalized = {}

	for _, spec in ipairs(specs) do
		if type(spec) == "string" then
			table.insert(normalized, github_url(spec))
		else
			local item = vim.deepcopy(spec)
			if item.source ~= nil then
				item.src = github_url(item.source)
				item.source = nil
			elseif item.src ~= nil then
				item.src = github_url(item.src)
			end

			if item.checkout ~= nil then
				item.version = item.checkout
				item.checkout = nil
			end

			item.depends = nil
			item.hooks = nil
			table.insert(normalized, item)
		end
	end

	vim.pack.add(normalized, vim.tbl_extend("force", { confirm = false }, opts or {}))
end

_G.Config.now = safely
_G.Config.later = function(fn)
	vim.schedule(function()
		safely(fn)
	end)
end
_G.Config.now_if_args = vim.fn.argc(-1) > 0 and _G.Config.now or _G.Config.later

_G.Config.pack_add({
	"nvim-mini/mini.nvim",
})
