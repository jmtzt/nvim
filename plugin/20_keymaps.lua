local nmap = function(lhs, rhs, desc)
	-- See `:h vim.keymap.set()`
	vim.keymap.set("n", lhs, rhs, { desc = desc })
end

vim.schedule(function()
	vim.opt.clipboard = "unnamedplus"
end)

vim.keymap.set({ "n", "x" }, "s", "<Nop>")

nmap("[p", '<Cmd>exe "put! " . v:register<CR>', "Paste Above")
nmap("]p", '<Cmd>exe "put "  . v:register<CR>', "Paste Below")

vim.keymap.set("n", "[b", ":bp<CR>", { desc = "Previous buffer" })

vim.keymap.set("n", "]b", ":bn<CR>", { desc = "Next buffer" })

vim.keymap.set("n", "J", "mzJ`z", { desc = "Join lines without moving cursor" })

vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result centered" })

vim.keymap.set("n", "N", "Nzzzv", { desc = "Previous search result centered" })

vim.keymap.set("n", "Q", "<nop>", { desc = "Disable Q" })

vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half-page down + center" })

vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half-page up + center" })

vim.keymap.set("n", "<M-[>", "<cmd>cnext<CR>", { desc = "Next quickfix item" })

vim.keymap.set("n", "<M-]>", "<cmd>cprev<CR>", { desc = "Previous quickfix item" })

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Maps <leader>tt to create a new todo entry
vim.keymap.set("n", "<leader>tt", function()
	-- 1. Get today's date formatted as YYYY-MM-DD
	local currentDate = os.date("%Y-%m-%d")

	-- 2. Construct the text for the new line
	local newLine = "[ ] " .. currentDate .. " " .. currentDate .. " "

	-- 3. Get the current cursor's line number
	local lnum = vim.api.nvim_win_get_cursor(0)[1]

	-- 4. Insert the new line of text below the current line
	vim.api.nvim_buf_set_lines(0, lnum, lnum, false, { newLine })

	-- 5. Move the cursor to the end of the newly inserted line
	vim.api.nvim_win_set_cursor(0, { lnum + 1, #newLine })

	-- 6. Enter insert mode
	vim.cmd("startinsert")
end, { desc = "Add new todo task entry" })

-- Maps <leader>td to toggle the todo item's done status
vim.keymap.set("n", "<leader>td", function()
	-- 1. Get the content of the current line
	local line = vim.api.nvim_get_current_line()

	-- 2. Check if the line starts with a checked box '[x]'
	if line:match("^%[x%]") then
		-- If so, replace it with an empty box '[ ]'
		local modifiedLine = line:gsub("^%[x%]", "[ ]")
		vim.api.nvim_set_current_line(modifiedLine)
	-- 3. Otherwise, check if the line starts with an empty box '[ ]'
	elseif line:match("^%[ %]") then
		-- If so, replace it with a checked box '[x]'
		local modifiedLine = line:gsub("^%[ %]", "[x]")
		vim.api.nvim_set_current_line(modifiedLine)
	end
end, { desc = "Toggle todo done status" })

vim.keymap.set("i", "jk", "<Esc>")

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })

vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

_G.Config.leader_group_clues = {
	{ mode = "n", keys = "<Leader>a", desc = "+Harpoon add" },
	{ mode = "n", keys = "<Leader>b", desc = "+Buffer" },
	{ mode = "n", keys = "<Leader>e", desc = "+Explore/Edit" },
	{ mode = "n", keys = "<Leader>s", desc = "+Find" },
	{ mode = "n", keys = "<Leader>g", desc = "+Git" },
	{ mode = "n", keys = "<Leader>l", desc = "+Language" },
	{ mode = "n", keys = "<Leader>m", desc = "+Map" },
	{ mode = "n", keys = "<Leader>o", desc = "+Other" },
	{ mode = "n", keys = "<Leader>f", desc = "+Session" },
	{ mode = "n", keys = "<Leader>t", desc = "+Todo" },
	{ mode = "n", keys = "<Leader>v", desc = "+Visits" },
	{ mode = "n", keys = "<Leader>d", desc = "+DAP" },
	{ mode = "n", keys = "<Leader>n", desc = "+Neotest" },
	{ mode = "n", keys = "<Leader>q", desc = "+Quickfix" },
	{ mode = "x", keys = "<Leader>g", desc = "+Git" },
	{ mode = "x", keys = "<Leader>l", desc = "+Language" },
}

local nmap_leader = function(suffix, rhs, desc)
	vim.keymap.set("n", "<Leader>" .. suffix, rhs, { desc = desc })
end
local xmap_leader = function(suffix, rhs, desc)
	vim.keymap.set("x", "<Leader>" .. suffix, rhs, { desc = desc })
end

local new_scratch_buffer = function()
	vim.api.nvim_win_set_buf(0, vim.api.nvim_create_buf(true, true))
end

nmap_leader("ba", "<Cmd>b#<CR>", "Alternate")
nmap_leader("bd", "<Cmd>lua MiniBufremove.delete()<CR>", "Delete")
nmap_leader("bD", "<Cmd>lua MiniBufremove.delete(0, true)<CR>", "Delete!")
nmap_leader("bs", new_scratch_buffer, "Scratch")
nmap_leader("bw", "<Cmd>lua MiniBufremove.wipeout()<CR>", "Wipeout")
nmap_leader("bW", "<Cmd>lua MiniBufremove.wipeout(0, true)<CR>", "Wipeout!")

local edit_plugin_file = function(filename)
	return string.format("<Cmd>edit %s/plugin/%s<CR>", vim.fn.stdpath("config"), filename)
end
local explore_quickfix = function()
	for _, win_id in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if vim.fn.getwininfo(win_id)[1].quickfix == 1 then
			return vim.cmd("cclose")
		end
	end
	vim.cmd("copen")
end

nmap_leader("ed", "<Cmd>Oil<CR>", "Directory")
nmap_leader("ei", "<Cmd>edit $MYVIMRC<CR>", "init.lua")
nmap_leader("ek", edit_plugin_file("20_keymaps.lua"), "Keymaps config")
nmap_leader("em", edit_plugin_file("30_mini.lua"), "MINI config")
nmap_leader("en", "<Cmd>lua MiniNotify.show_history()<CR>", "Notifications")
nmap_leader("eo", edit_plugin_file("10_options.lua"), "Options config")
nmap_leader("ep", edit_plugin_file("40_plugins.lua"), "Plugins config")
nmap_leader("eq", explore_quickfix, "Quickfix")

nmap_leader("qq", explore_quickfix, "Quickfix")
nmap_leader("qj", "<cmd>cnext<CR>", "Next Quickfix item")
nmap_leader("qk", "<cmd>cprev<CR>", "Prev Quickfix item")

local formatting_cmd = '<Cmd>lua require("conform").format({lsp_fallback=true})<CR>'

nmap_leader("la", "<Cmd>lua vim.lsp.buf.code_action()<CR>", "Actions")
nmap_leader("ld", "<Cmd>lua vim.diagnostic.open_float()<CR>", "Diagnostic popup")
nmap_leader("lf", formatting_cmd, "Format")
nmap_leader("li", "<Cmd>lua vim.lsp.buf.implementation()<CR>", "Implementation")
nmap_leader("lh", "<Cmd>lua vim.lsp.buf.hover()<CR>", "Hover")
nmap_leader("lr", "<Cmd>lua vim.lsp.buf.rename()<CR>", "Rename")
nmap_leader("lR", "<Cmd>lua vim.lsp.buf.references()<CR>", "References")
nmap_leader("ls", "<Cmd>lua vim.lsp.buf.definition()<CR>", "Source definition")
nmap_leader("lt", "<Cmd>lua vim.lsp.buf.type_definition()<CR>", "Type definition")

xmap_leader("lf", formatting_cmd, "Format selection")

nmap_leader("mf", "<Cmd>lua MiniMap.toggle_focus()<CR>", "Focus (toggle)")
nmap_leader("mr", "<Cmd>lua MiniMap.refresh()<CR>", "Refresh")
nmap_leader("ms", "<Cmd>lua MiniMap.toggle_side()<CR>", "Side (toggle)")
nmap_leader("mt", "<Cmd>lua MiniMap.toggle()<CR>", "Toggle")

nmap_leader("or", "<Cmd>lua MiniMisc.resize_window()<CR>", "Resize to default width")
nmap_leader("ot", "<Cmd>lua MiniTrailspace.trim()<CR>", "Trim trailspace")
nmap_leader("oz", "<Cmd>lua MiniMisc.zoom()<CR>", "Zoom toggle")

local session_new = 'MiniSessions.write(vim.fn.input("Session name: "))'

nmap_leader("fd", '<Cmd>lua MiniSessions.select("delete")<CR>', "Delete")
nmap_leader("fn", "<Cmd>lua " .. session_new .. "<CR>", "New")
nmap_leader("fr", '<Cmd>lua MiniSessions.select("read")<CR>', "Read")
nmap_leader("fw", "<Cmd>lua MiniSessions.write()<CR>", "Write current")

nmap_leader("tT", "<Cmd>horizontal term<CR>", "Terminal (horizontal)")
nmap_leader("tt", "<Cmd>vertical term<CR>", "Terminal (vertical)")

local make_pick_core = function(cwd, desc)
	return function()
		local sort_latest = MiniVisits.gen_sort.default({ recency_weight = 1 })
		local local_opts = { cwd = cwd, filter = "core", sort = sort_latest }
		MiniExtra.pickers.visit_paths(local_opts, { source = { name = desc } })
	end
end

nmap_leader("vc", make_pick_core("", "Core visits (all)"), "Core visits (all)")
nmap_leader("vC", make_pick_core(nil, "Core visits (cwd)"), "Core visits (cwd)")
nmap_leader("vv", '<Cmd>lua MiniVisits.add_label("core")<CR>', 'Add "core" label')
nmap_leader("vV", '<Cmd>lua MiniVisits.remove_label("core")<CR>', 'Remove "core" label')
nmap_leader("vl", "<Cmd>lua MiniVisits.add_label()<CR>", "Add label")
nmap_leader("vL", "<Cmd>lua MiniVisits.remove_label()<CR>", "Remove label")

nmap_leader("na", "<cmd>Neotest attach<cr>", "Attach")
nmap_leader("nr", "<cmd>Neotest run<cr>", "Run")
nmap_leader("no", "<cmd>Neotest output<cr>", "Output")
nmap_leader("np", "<cmd>Neotest output-panel<cr>", "Output panel")
nmap_leader("ns", "<cmd>Neotest stop<cr>", "Stop")
nmap_leader("nm", "<cmd>Neotest summary<cr>", "Summary")
