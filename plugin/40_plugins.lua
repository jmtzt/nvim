-- ┌─────────────────────────┐
-- │ Plugins outside of MINI │
-- └─────────────────────────┘
--
-- This file contains installation and configuration of plugins outside of MINI.
-- They significantly improve user experience in a way not yet possible with MINI.
-- These are mostly plugins that provide programming language specific behavior.
--
-- Use this file to install and configure other such plugins.

-- Make concise helpers for installing/adding plugins in two stages
local add, later = MiniDeps.add, MiniDeps.later
local now_if_args = _G.Config.now_if_args

-- Tree-sitter ================================================================

-- Tree-sitter is a tool for fast incremental parsing. It converts text into
-- a hierarchical structure (called tree) that can be used to implement advanced
-- and/or more precise actions: syntax highlighting, textobjects, indent, etc.
--
-- Tree-sitter support is built into Neovim (see `:h treesitter`). However, it
-- requires two extra pieces that don't come with Neovim directly:
-- - Language parsers: programs that convert text into trees. Some are built-in
--   (like for Lua), 'nvim-treesitter' provides many others.
-- - Query files: definitions of how to extract information from trees in
--   a useful manner (see `:h treesitter-query`). 'nvim-treesitter' also provides
--   these, while 'nvim-treesitter-textobjects' provides the ones for Neovim
--   textobjects (see `:h text-objects`, `:h MiniAi.gen_spec.treesitter()`).
--
-- Add these plugins now if file (and not 'mini.starter') is shown after startup.
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

-- Language servers ===========================================================

-- Language Server Protocol (LSP) is a set of conventions that power creation of
-- language specific tools. It requires two parts:
-- - Server - program that performs language specific computations.
-- - Client - program that asks server for computations and shows results.
--
-- Here Neovim itself is a client (see `:h vim.lsp`). Language servers need to
-- be installed separately based on your OS, CLI tools, and preferences.
-- See note about 'mason.nvim' at the bottom of the file.
--
-- Neovim's team collects commonly used configurations for most language servers
-- inside 'neovim/nvim-lspconfig' plugin.
--
-- Add it now if file (and not 'mini.starter') is shown after startup.
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

	vim.lsp.enable("luals")
	vim.lsp.enable("pyright")
	vim.lsp.enable("ruff")
	vim.lsp.enable("ty")

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
			map("gd", "<Cmd>lua vim.lsp.buf.definition()<CR>", "[G]oto [D]efinition")

			-- -- Find references for the word under your cursor.
			map("gr", "<Cmd>lua vim.lsp.buf.references()<CR>", "[G]oto [R]eferences")
			map("grr", "<Cmd>lua vim.lsp.buf.references()<CR>", "[G]oto [R]eferences")
			map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

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

-- Formatting =================================================================

-- Programs dedicated to text formatting (a.k.a. formatters) are very useful.
-- Neovim has built-in tools for text formatting (see `:h gq` and `:h 'formatprg'`).
-- They can be used to configure external programs, but it might become tedious.
--
-- The 'stevearc/conform.nvim' plugin is a good and maintained solution for easier
-- formatting setup.
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
end)

-- Snippets ===================================================================

-- Although 'mini.snippets' provides functionality to manage snippet files, it
-- deliberately doesn't come with those.
--
-- The 'rafamadriz/friendly-snippets' is currently the largest collection of
-- snippet files. They are organized in 'snippets/' directory (mostly) per language.
-- 'mini.snippets' is designed to work with it as seamlessly as possible.
-- See `:h MiniSnippets.gen_loader.from_lang()`.
later(function()
	add("rafamadriz/friendly-snippets")
end)

-- Honorable mentions =========================================================

-- 'mason-org/mason.nvim' (a.k.a. "Mason") is a great tool (package manager) for
-- installing external language servers, formatters, and linters. It provides
-- a unified interface for installing, updating, and deleting such programs.
--
-- The caveat is that these programs will be set up to be mostly used inside Neovim.
-- If you need them to work elsewhere, consider using other package managers.
--
-- You can use it like so:
later(function()
	add("mason-org/mason.nvim")
	require("mason").setup()
end)

later(function()
	add("mason-org/mason-registry")
	add("williamboman/mason-lspconfig.nvim")
	add("WhoIsSethDaniel/mason-tool-installer.nvim")
        add("stevearc/oil.nvim")
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
        require("kotlin").setup {
            root_markers = {
                "gradlew",
                ".git",
                "mvnw",
                "settings.gradle",
            },
            jvm_args = {
                "-Xmx24g",
            },
        }
end)

-- Harpoon ===================================================================
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

-- Neotest ===================================================================
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

-- DAP ===================================================================
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
-- DAP UI ===================================================================
later(function()
	add("rcarriga/nvim-dap-ui")
	vim.keymap.set("n", "<leader>du", function()
		require("dapui").toggle()
	end, { desc = "Toggle DAP UI" })
end)

-- Copilot ===================================================================
later(function()
	add("github/copilot.vim")
	vim.api.nvim_set_keymap("i", "<C-l>", 'copilot#Accept("<CR>")', { silent = true, expr = true })
end)

-- LazyGit ===================================================================
later(function()
	add("kdheepak/lazygit.nvim")
end)

-- Beautiful, usable, well maintained color schemes outside of 'mini.nvim' and
-- have full support of its highlight groups. Use if you don't like 'miniwinter'
-- enabled in 'plugin/30_mini.lua' or other suggested 'mini.hues' based ones.
MiniDeps.now(function()
	-- Install only those that you need
	add("rose-pine/neovim")

	-- Enable only one
	vim.cmd("color rose-pine")
end)
