local add, later = MiniDeps.add, MiniDeps.later
local now_if_args = _G.Config.now_if_args

now_if_args(function()
	add({
		source = "nvim-treesitter/nvim-treesitter",
		-- Use `main` branch since `master` branch is frozen, yet still default
		checkout = "main",
		-- Update tree-sitter parser after plugin is updated
		hooks = {
			post_checkout = function()
				vim.cmd("TSUpdate")
			end,
		},
	})
	add({
		source = "nvim-treesitter/nvim-treesitter-textobjects",
		-- Same logic as for 'nvim-treesitter'
		checkout = "main",
	})

	local languages = {
		"lua",
		"vimdoc",
		"markdown",
		"python",
		"bash",
		"c",
		"diff",
		"html",
		"luadoc",
		"markdown",
		"markdown_inline",
		"python",
		"query",
		"vim",
		"vimdoc",
		"zig",
	}
	local isnt_installed = function(lang)
		return #vim.api.nvim_get_runtime_file("parser/" .. lang .. ".*", false) == 0
	end
	local to_install = vim.tbl_filter(isnt_installed, languages)
	if #to_install > 0 then
		require("nvim-treesitter").install(to_install)
	end

	-- Enable tree-sitter after opening a file for a target language
	local filetypes = {}
	for _, lang in ipairs(languages) do
		for _, ft in ipairs(vim.treesitter.language.get_filetypes(lang)) do
			table.insert(filetypes, ft)
		end
	end
	local ts_start = function(ev)
		vim.treesitter.start(ev.buf)
	end
	_G.Config.new_autocmd("FileType", filetypes, ts_start, "Start tree-sitter")
end)

now_if_args(function()
	add("neovim/nvim-lspconfig")

	-- Use `:h vim.lsp.enable()` to automatically enable language server based on
	-- the rules provided by 'nvim-lspconfig'.
	-- Use `:h vim.lsp.config()` or 'ftplugin/lsp/' directory to configure servers.
	-- Uncomment and tweak the following `vim.lsp.enable()` call to enable servers.
	vim.lsp.config("ty", {
		settings = {
			ty = {
				disableLanguageServices = true,
			},
		},
	})

	vim.lsp.config("ruff", {
		on_attach = function(client)
			client.server_capabilities.hoverProvider = false
		end,

		init_options = {
			settings = {
				args = {
					"--ignore",
					"F821",
					"--ignore",
					"E402",
					"--ignore",
					"E722",
					"--ignore",
					"E712",
				},
			},
		},
	})

	vim.lsp.config("pyright", {
		settings = {
			python = {
				pyright = {
					disableOrganizeImports = true,
				},
				analysis = {
					-- Ignore all files for analysis to exclusively use Ruff for linting
					ignore = { "*" },
				},
			},
		},
	})

	vim.lsp.config("zls", {
		cmd = { "zls" },
		filetypes = { "zig", "zir" },
		single_file_support = true,
		enable_build_on_save = true,
	})

	-- Configure jsonls with custom capabilities
	local capabilities = vim.lsp.protocol.make_client_capabilities()
	capabilities.textDocument.completion.completionItem.snippetSupport = true

	vim.lsp.config("jsonls", {
		capabilities = capabilities,
		init_options = {
			provideFormatter = false,
		},
	})

	-- Lazy load LSPs per filetype - only loads when you open a file of that type
	local lsp_enabled = {} -- Track which LSPs have been enabled

	local function enable_lsp_once(lsp_name)
		if not lsp_enabled[lsp_name] then
			vim.lsp.enable(lsp_name)
			lsp_enabled[lsp_name] = true
		end
	end

	-- Lua files
	vim.api.nvim_create_autocmd("FileType", {
		pattern = "lua",
		callback = function()
			enable_lsp_once("luals")
		end,
	})

	-- Python files
	vim.api.nvim_create_autocmd("FileType", {
		pattern = "python",
		callback = function()
			enable_lsp_once("pyright")
			enable_lsp_once("ruff")
			enable_lsp_once("ty")
		end,
	})

	-- Zig files
	vim.api.nvim_create_autocmd("FileType", {
		pattern = { "zig", "zir" },
		callback = function()
			enable_lsp_once("zls")
		end,
	})

	-- JSON files
	vim.api.nvim_create_autocmd("FileType", {
		pattern = "json",
		callback = function()
			enable_lsp_once("jsonls")
		end,
	})

	vim.api.nvim_create_autocmd("LspAttach", {
		group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
		callback = function(event)
			-- NOTE: Remember that Lua is a real programming language, and as such it is possible
			-- to define small helper and utility functions so you don't have to repeat yourself.
			--
			-- In this case, we create a function that lets us more easily define mappings specific
			-- for LSP related items. It sets the mode, buffer and description for us each time.
			local map = function(keys, func, desc, mode)
				mode = mode or "n"
				vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
			end

			-- Jump to the definition of the word under your cursor.
			--  This is where a variable was first declared, or where a function is defined, etc.
			--  To jump back, press <C-t>.
			-- map("gd", "<Cmd>lua vim.lsp.buf.definition()<CR>", "[G]oto [D]efinition")

			-- -- Find references for the word under your cursor.
			-- map("gr", "<Cmd>lua vim.lsp.buf.references()<CR>", "[G]oto [R]eferences")
			-- map("grr", "<Cmd>lua vim.lsp.buf.references()<CR>", "[G]oto [R]eferences")
			-- map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

			-- This function resolves a difference between neovim nightly (version 0.11) and stable (version 0.10)
			---@param client vim.lsp.Client
			---@param method vim.lsp.protocol.Method
			---@param bufnr? integer some lsp support methods only in specific files
			---@return boolean
			local function client_supports_method(client, method, bufnr)
				-- if vim.fn.has("nvim-0.12") == 1 then
				return client:supports_method(method, bufnr)
				-- else
				-- 	return client.supports_method(method, { bufnr = bufnr })
				-- end
			end

			-- The following two autocommands are used to highlight references of the
			-- word under your cursor when your cursor rests there for a little while.
			--    See `:help CursorHold` for information about when this is executed
			--
			-- When you move your cursor, the highlights will be cleared (the second autocommand).
			local client = vim.lsp.get_client_by_id(event.data.client_id)
			if
				client
				and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf)
			then
				local highlight_augroup = vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
				vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
					buffer = event.buf,
					group = highlight_augroup,
					callback = vim.lsp.buf.document_highlight,
				})

				vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
					buffer = event.buf,
					group = highlight_augroup,
					callback = vim.lsp.buf.clear_references,
				})

				vim.api.nvim_create_autocmd("LspDetach", {
					group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
					callback = function(event2)
						vim.lsp.buf.clear_references()
						vim.api.nvim_clear_autocmds({ group = "kickstart-lsp-highlight", buffer = event2.buf })
					end,
				})
			end
			require("mini.clue").ensure_buf_triggers()
		end,
	})
end)

later(function()
	add("stevearc/conform.nvim")

	-- See also:
	-- - `:h Conform`
	-- - `:h conform-options`
	-- - `:h conform-formatters`
	require("conform").setup({
		-- Map of filetype to formatters
		-- Make sure that necessary CLI tool is available
		formatters_by_ft = {
			lua = { "stylua" },
			python = { "ruff", "ruff_fix", "ruff_organize_imports", "ruff_format" },
			json = { "jq" },
		},
		notify_on_error = false,
		format_on_save = function(bufnr)
			-- Disable "format_on_save lsp_fallback" for languages that don't
			-- have a well standardized coding style. You can add additional
			-- languages here or re-enable it for the disabled ones.
			local disable_filetypes = { c = true, cpp = true }
			if disable_filetypes[vim.bo[bufnr].filetype] then
				return nil
			else
				return {
					timeout_ms = 5000,
					lsp_format = "fallback",
				}
			end
		end,
	})
	local conform = require("conform")

	conform.formatters.jq = {
		args = { "." }, -- equivalent to `jq .`
	}
end)

later(function()
	add("rafamadriz/friendly-snippets")
end)

later(function()
	add("mason-org/mason.nvim")
	require("mason").setup()
end)

later(function()
	add("mason-org/mason-registry")
	add("williamboman/mason-lspconfig.nvim")
	add("WhoIsSethDaniel/mason-tool-installer.nvim")
	add("stevearc/oil.nvim")
	vim.keymap.set("n", "<leader>st", "<CMD>Oil<CR>", { desc = "Open file explorer" })
	require("oil").setup({
		view_options = {
			show_hidden = true,
		},
	})

	add("AlexandrosAlexiou/kotlin.nvim")

	local ensure_installed = vim.tbl_keys({})
	vim.list_extend(ensure_installed, {
		"stylua", -- Used to format Lua code
		"ruff",
		"pyright",
	})
	require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

	require("mason-lspconfig").setup({
		ensure_installed = {}, -- explicitly set to an empty table (Kickstart populates installs via mason-tool-installer)
		automatic_installation = false,
		handlers = {
			function(server_name)
				local server = servers[server_name] or {}
				-- This handles overriding only values explicitly passed
				-- by the server configuration above. Useful when disabling
				-- certain features of an LSP (for example, turning off formatting for ts_ls)
				server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
				--require('lspconfig')[server_name].setup(server)
				vim.lsp.config(server_name, server)
			end,
		},
	})
	require("kotlin").setup({
		root_markers = {
			"gradlew",
			".git",
			"mvnw",
			"settings.gradle",
		},
		jvm_args = {
			"-Xmx24g",
		},
	})
end)

later(function()
	add("nvim-lua/plenary.nvim")
	add({
		source = "theprimeagen/harpoon",
		checkout = "harpoon2",
	})
	local harpoon = require("harpoon")

	-- REQUIRED
	harpoon:setup()
	-- REQUIRED

	vim.keymap.set("n", "<leader>a", function()
		harpoon:list():add()
	end, { desc = "+Harpoon add" })
	vim.keymap.set("n", "<C-e>", function()
		harpoon.ui:toggle_quick_menu(harpoon:list())
	end)

	vim.keymap.set("n", "<C-t>", function()
		harpoon:list():select(1)
	end)
	vim.keymap.set("n", "<C-y>", function()
		harpoon:list():select(2)
	end)
	vim.keymap.set("n", "<C-n>", function()
		harpoon:list():select(3)
	end)
	vim.keymap.set("n", "<C-s>", function()
		harpoon:list():select(4)
	end)
end)

later(function()
	add("nvim-neotest/neotest")
	add("nvim-neotest/nvim-nio")
	add("nvim-lua/plenary.nvim")
	add("antoinemadec/FixCursorHold.nvim")
	add("nvim-treesitter/nvim-treesitter")
	add("nvim-neotest/neotest-python")

	require("neotest").setup({
		log_level = "WARN",
		adapters = {
			require("neotest-python"),
		},
	})

	local lib = require("neotest.lib")

	lib.notify = function(msg, level)
		-- Drop totally silent notifications
		if level == vim.log.levels.OFF then
			return
		end

		-- Normalize weird inputs or unsupported numeric levels
		if type(level) ~= "number" then
			level = vim.log.levels.INFO
		end
		if not (level_names and level_names[level]) then
			level = vim.log.levels.INFO
		end

		-- Forward to normal vim.notify (MiniNotify will pick this up)
		return vim.notify(msg, level, { title = "neotest" })
	end
end)

later(function()
	add("mfussenegger/nvim-dap")
	add("theHamsta/nvim-dap-virtual-text")
	add("mfussenegger/nvim-dap-python")
	add("jay-babu/mason-nvim-dap.nvim")
	add("rcarriga/nvim-dap-ui")

	-- Keys
	vim.keymap.set("n", "<leader>dc", function()
		require("dap").continue()
	end, { desc = "Start/Continue Debugger" })
	vim.keymap.set("n", "<leader>db", function()
		require("dap").toggle_breakpoint()
	end, { desc = "Add Breakpoint" })
	vim.keymap.set("n", "<leader>dt", function()
		require("dap").terminate()
	end, { desc = "Terminate Debugger" })
	vim.keymap.set("n", "<leader>dl", function()
		require("dap").clear_breakpoints()
	end, { desc = "Clear breakpoints" })

	-- Config
	local dap = require("dap")
	local dapui = require("dapui")

	require("mason-nvim-dap").setup({
		automatic_setup = true,
		automatic_installation = true,
		handlers = {},
		ensure_installed = {
			"debugpy",
		},
	})

	dap.listeners.after.event_initialized["dapui_config"] = dapui.open
	dap.listeners.before.event_terminated["dapui_config"] = dapui.close
	dap.listeners.before.event_exited["dapui_config"] = dapui.close

	require("dapui").setup()
	require("dap-python").setup("uv")
end)
later(function()
	add("rcarriga/nvim-dap-ui")
	vim.keymap.set("n", "<leader>du", function()
		require("dapui").toggle()
	end, { desc = "Toggle DAP UI" })
end)

later(function()
	add("github/copilot.vim")
	vim.api.nvim_set_keymap("i", "<C-l>", 'copilot#Accept("<CR>")', { silent = true, expr = true })
end)

MiniDeps.now(function()
	add("folke/snacks.nvim")
	require("snacks").setup({
		bigfile = { enabled = false }, -- Disabled for debugging
		picker = { enabled = true },
		lazygit = { enabled = true },
		lazy = { enabled = false },
		dashboard = { enabled = false },
	})

	-- Define keys after setup
	vim.keymap.set("n", "<leader>sf", function()
		Snacks.picker.smart()
	end, { desc = "Smart Find Files" })
	vim.keymap.set("n", "<leader>sb", function()
		Snacks.picker.buffers()
	end, { desc = "Buffers" })
	vim.keymap.set("n", "<leader>sg", function()
		Snacks.picker.grep()
	end, { desc = "Grep" })
	vim.keymap.set("n", "<leader>sc", function()
		Snacks.picker.command_history()
	end, { desc = "Command History" })
	vim.keymap.set("n", "<leader>gg", function()
		Snacks.lazygit()
	end, { desc = "Lazygit" })
	-- find
	vim.keymap.set("n", "<leader>fb", function()
		Snacks.picker.buffers()
	end, { desc = "Buffers" })
	vim.keymap.set("n", "<leader>fc", function()
		Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
	end, { desc = "Find Config File" })
	vim.keymap.set("n", "<leader>ff", function()
		Snacks.picker.files()
	end, { desc = "Find Files" })
	vim.keymap.set("n", "<leader>fg", function()
		Snacks.picker.git_files()
	end, { desc = "Find Git Files" })
	vim.keymap.set("n", "<leader>fp", function()
		Snacks.picker.projects()
	end, { desc = "Projects" })
	vim.keymap.set("n", "<leader>fr", function()
		Snacks.picker.recent()
	end, { desc = "Recent" })
	-- git
	vim.keymap.set("n", "<leader>gb", function()
		Snacks.picker.git_branches()
	end, { desc = "Git Branches" })
	vim.keymap.set("n", "<leader>gl", function()
		Snacks.picker.git_log()
	end, { desc = "Git Log" })
	vim.keymap.set("n", "<leader>gL", function()
		Snacks.picker.git_log_line()
	end, { desc = "Git Log Line" })
	vim.keymap.set("n", "<leader>gs", function()
		Snacks.picker.git_status()
	end, { desc = "Git Status" })
	vim.keymap.set("n", "<leader>gS", function()
		Snacks.picker.git_stash()
	end, { desc = "Git Stash" })
	vim.keymap.set("n", "<leader>gd", function()
		Snacks.picker.git_diff()
	end, { desc = "Git Diff (Hunks)" })
	vim.keymap.set("n", "<leader>gf", function()
		Snacks.picker.git_log_file()
	end, { desc = "Git Log File" })
	-- gh
	vim.keymap.set("n", "<leader>gi", function()
		Snacks.picker.gh_issue()
	end, { desc = "GitHub Issues (open)" })
	vim.keymap.set("n", "<leader>gI", function()
		Snacks.picker.gh_issue({ state = "all" })
	end, { desc = "GitHub Issues (all)" })
	vim.keymap.set("n", "<leader>gp", function()
		Snacks.picker.gh_pr()
	end, { desc = "GitHub Pull Requests (open)" })
	vim.keymap.set("n", "<leader>gP", function()
		Snacks.picker.gh_pr({ state = "all" })
	end, { desc = "GitHub Pull Requests (all)" })
	-- Grep
	vim.keymap.set("n", "<leader>sb", function()
		Snacks.picker.lines()
	end, { desc = "Buffer Lines" })
	vim.keymap.set("n", "<leader>sB", function()
		Snacks.picker.grep_buffers()
	end, { desc = "Grep Open Buffers" })
	vim.keymap.set("n", "<leader>sg", function()
		Snacks.picker.grep()
	end, { desc = "Grep" })
	vim.keymap.set({ "n", "x" }, "<leader>sw", function()
		Snacks.picker.grep_word()
	end, { desc = "Visual selection or word" })
	-- search
	vim.keymap.set("n", '<leader>s"', function()
		Snacks.picker.registers()
	end, { desc = "Registers" })
	vim.keymap.set("n", "<leader>s/", function()
		Snacks.picker.search_history()
	end, { desc = "Search History" })
	vim.keymap.set("n", "<leader>sa", function()
		Snacks.picker.autocmds()
	end, { desc = "Autocmds" })
	vim.keymap.set("n", "<leader>sb", function()
		Snacks.picker.lines()
	end, { desc = "Buffer Lines" })
	vim.keymap.set("n", "<leader>sc", function()
		Snacks.picker.command_history()
	end, { desc = "Command History" })
	vim.keymap.set("n", "<leader>sC", function()
		Snacks.picker.commands()
	end, { desc = "Commands" })
	vim.keymap.set("n", "<leader>sd", function()
		Snacks.picker.diagnostics()
	end, { desc = "Diagnostics" })
	vim.keymap.set("n", "<leader>sD", function()
		Snacks.picker.diagnostics_buffer()
	end, { desc = "Buffer Diagnostics" })
	vim.keymap.set("n", "<leader>sh", function()
		Snacks.picker.help()
	end, { desc = "Help Pages" })
	vim.keymap.set("n", "<leader>sH", function()
		Snacks.picker.highlights()
	end, { desc = "Highlights" })
	vim.keymap.set("n", "<leader>si", function()
		Snacks.picker.icons()
	end, { desc = "Icons" })
	vim.keymap.set("n", "<leader>sj", function()
		Snacks.picker.jumps()
	end, { desc = "Jumps" })
	vim.keymap.set("n", "<leader>sk", function()
		Snacks.picker.keymaps()
	end, { desc = "Keymaps" })
	vim.keymap.set("n", "<leader>sl", function()
		Snacks.picker.loclist()
	end, { desc = "Location List" })
	vim.keymap.set("n", "<leader>sm", function()
		Snacks.picker.marks()
	end, { desc = "Marks" })
	vim.keymap.set("n", "<leader>sM", function()
		Snacks.picker.man()
	end, { desc = "Man Pages" })
	-- vim.keymap.set("n", "<leader>sp", function()
	--   Snacks.picker.lazy()
	-- end, { desc = "Search for Plugin Spec" })
	vim.keymap.set("n", "<leader>sq", function()
		Snacks.picker.qflist()
	end, { desc = "Quickfix List" })
	vim.keymap.set("n", "<leader>sR", function()
		Snacks.picker.resume()
	end, { desc = "Resume" })
	vim.keymap.set("n", "<leader>su", function()
		Snacks.picker.undo()
	end, { desc = "Undo History" })
	vim.keymap.set("n", "<leader>uC", function()
		Snacks.picker.colorschemes()
	end, { desc = "Colorschemes" })
	-- LSP
	vim.keymap.set("n", "gd", function()
		Snacks.picker.lsp_definitions()
	end, { desc = "Goto Definition" })
	vim.keymap.set("n", "gD", function()
		Snacks.picker.lsp_declarations()
	end, { desc = "Goto Declaration" })
	vim.keymap.set("n", "gr", function()
		Snacks.picker.lsp_references()
	end, { desc = "References", nowait = true })
	vim.keymap.set("n", "gI", function()
		Snacks.picker.lsp_implementations()
	end, { desc = "Goto Implementation" })
	vim.keymap.set("n", "gy", function()
		Snacks.picker.lsp_type_definitions()
	end, { desc = "Goto T[y]pe Definition" })
	vim.keymap.set("n", "gai", function()
		Snacks.picker.lsp_incoming_calls()
	end, { desc = "C[a]lls Incoming" })
	vim.keymap.set("n", "gao", function()
		Snacks.picker.lsp_outgoing_calls()
	end, { desc = "C[a]lls Outgoing" })
	vim.keymap.set("n", "<leader>ss", function()
		Snacks.picker.lsp_symbols()
	end, { desc = "LSP Symbols" })
	vim.keymap.set("n", "<leader>sS", function()
		Snacks.picker.lsp_workspace_symbols()
	end, { desc = "LSP Workspace Symbols" })

	vim.cmd([[au FileType snacks_picker_input lua vim.b.minicompletion_disable = true]])
end)

later(function()
	add("kevinhwang91/promise-async")
	add("kevinhwang91/nvim-ufo")

	vim.o.foldcolumn = "1"
	vim.o.foldlevel = 99
	vim.o.foldlevelstart = 99
	vim.o.foldenable = true

	-- Using ufo provider need remap `zR` and `zM`. If Neovim is 0.6.1, remap yourself
	vim.keymap.set("n", "zR", require("ufo").openAllFolds)
	vim.keymap.set("n", "zM", require("ufo").closeAllFolds)

	-- treesitter as a main provider instead
	-- ufo uses the same query files for folding (queries/<lang>/folds.scm)
	-- performance and stability are better than `foldmethod=nvim_treesitter#foldexpr()`
	require("ufo").setup({
		provider_selector = function(bufnr, filetype, buftype)
			return { "treesitter", "indent" }
		end,
	})
	--
end)

later(function()
	add("mrjones2014/smart-splits.nvim")
	vim.keymap.set("n", "<C-h>", require("smart-splits").move_cursor_left, { desc = "Move cursor left" })
	vim.keymap.set("n", "<C-j>", require("smart-splits").move_cursor_down, { desc = "Move cursor down" })
	vim.keymap.set("n", "<C-k>", require("smart-splits").move_cursor_up, { desc = "Move cursor up" })
	vim.keymap.set("n", "<C-l>", require("smart-splits").move_cursor_right, { desc = "Move cursor right" })
	vim.keymap.set(
		"n",
		"<C-\\>",
		require("smart-splits").move_cursor_previous,
		{ desc = "Move cursor to previous window" }
	)
	-- swapping buffers between windows
	vim.keymap.set("n", "<leader><leader>h", require("smart-splits").swap_buf_left, { desc = "Swap buffer left" })
	vim.keymap.set("n", "<leader><leader>j", require("smart-splits").swap_buf_down, { desc = "Swap buffer down" })
	vim.keymap.set("n", "<leader><leader>k", require("smart-splits").swap_buf_up, { desc = "Swap buffer up" })
	vim.keymap.set("n", "<leader><leader>l", require("smart-splits").swap_buf_right, { desc = "Swap buffer right" })
end)

later(function()
	add({
		source = "harrisoncramer/gitlab.nvim",
		depends = {
			"MunifTanjim/nui.nvim",
			"nvim-lua/plenary.nvim",
			"sindrets/diffview.nvim",
			"stevearc/dressing.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		hooks = {
			post_checkout = function()
				require("gitlab.server").build(true) -- Builds the Go binary
			end,
		},
	})

	require("gitlab").setup()
end)

later(function()
	add({
		source = "esmuellert/codediff.nvim",
		depends = {
			"MunifTanjim/nui.nvim",
		},
	})

	require("codediff").setup()
	vim.keymap.set("n", "<leader>gv", ":CodeDiff<CR>", { desc = "Open DiffView" })
end)

MiniDeps.now(function()
	-- Install only those that you need
	add("rose-pine/neovim")
	add("rebelot/kanagawa.nvim")
	add("Mofiqul/dracula.nvim")

	-- Enable only one
	vim.cmd("color rose-pine-main")
end)
