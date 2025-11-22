local now, later = MiniDeps.now, MiniDeps.later
local now_if_args = _G.Config.now_if_args

now(function()
	vim.cmd("colorscheme miniwinter")
end)

now(function()
	require("mini.basics").setup({
		-- Manage options in 'plugin/10_options.lua' for didactic purposes
		options = { basic = false },
		mappings = {
			-- Create `<C-hjkl>` mappings for window navigation
			windows = false,
			-- Create `<M-hjkl>` mappings for navigation in Insert and Command modes
			move_with_alt = true,
		},
	})
end)

now(function()
	-- Set up to not prefer extension-based icon for some extensions
	local ext3_blocklist = { scm = true, txt = true, yml = true }
	local ext4_blocklist = { json = true, yaml = true }
	require("mini.icons").setup({
		use_file_extension = function(ext, _)
			return not (ext3_blocklist[ext:sub(-3)] or ext4_blocklist[ext:sub(-4)])
		end,
	})

	-- Mock 'nvim-tree/nvim-web-devicons' for plugins without 'mini.icons' support.
	-- Not needed for 'mini.nvim' or MiniMax, but might be useful for others.
	later(MiniIcons.mock_nvim_web_devicons)

	-- Add LSP kind icons. Useful for 'mini.completion'.
	later(MiniIcons.tweak_lsp_kind)
end)

now_if_args(function()
	-- Makes `:h MiniMisc.put()` and `:h MiniMisc.put_text()` public
	require("mini.misc").setup()

	-- Change current working directory based on the current file path. It
	-- searches up the file tree until the first root marker ('.git' or 'Makefile')
	-- and sets their parent directory as a current directory.
	-- This is helpful when simultaneously dealing with files from several projects.
	MiniMisc.setup_auto_root()

	-- Restore latest cursor position on file open
	MiniMisc.setup_restore_cursor()

	-- Synchronize terminal emulator background with Neovim's background to remove
	-- possibly different color padding around Neovim instance
	MiniMisc.setup_termbg_sync()
end)

now(function()
	require("mini.notify").setup()
end)

now(function()
	require("mini.sessions").setup()
end)

later(function()
	require("mini.extra").setup()
end)

later(function()
	local ai = require("mini.ai")
	ai.setup({
		-- 'mini.ai' can be extended with custom textobjects
		custom_textobjects = {
			-- Make `aB` / `iB` act on around/inside whole *b*uffer
			B = MiniExtra.gen_ai_spec.buffer(),
			-- For more complicated textobjects that require structural awareness,
			-- use tree-sitter. This example makes `aF`/`iF` mean around/inside function
			-- definition (not call). See `:h MiniAi.gen_spec.treesitter()` for details.
			F = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
		},

		-- 'mini.ai' by default mostly mimics built-in search behavior: first try
		-- to find textobject covering cursor, then try to find to the right.
		-- Although this works in most cases, some are confusing. It is more robust to
		-- always try to search only covering textobject and explicitly ask to search
		-- for next (`an`/`in`) or last (`al`/`il`).
		-- Try this. If you don't like it - delete next line and this comment.
		search_method = "cover",
	})
end)

later(function()
	require("mini.align").setup()
end)

later(function()
	require("mini.bracketed").setup()
end)

later(function()
	require("mini.bufremove").setup()
end)

later(function()
	local miniclue = require("mini.clue")
  -- stylua: ignore
  miniclue.setup({
    -- Define which clues to show. By default shows only clues for custom mappings
    -- (uses `desc` field from the mapping; takes precedence over custom clue).
    clues = {
      -- This is defined in 'plugin/20_keymaps.lua' with Leader group descriptions
      Config.leader_group_clues,
      miniclue.gen_clues.builtin_completion(),
      miniclue.gen_clues.marks(),
      miniclue.gen_clues.registers(),
      -- This creates a submode for window resize mappings. Try the following:
      -- - Press `<C-w>s` to make a window split.
      -- - Press `<C-w>+` to increase height. Clue window still shows clues as if
      --   `<C-w>` is pressed again. Keep pressing just `+` to increase height.
      --   Try pressing `-` to decrease height.
      -- - Stop submode either by `<Esc>` or by any key that is not in submode.
      miniclue.gen_clues.windows({ submode_resize = true }),
      miniclue.gen_clues.z(),
    },
    -- Explicitly opt-in for set of common keys to trigger clue window
    triggers = {
      { mode = 'n', keys = '<Leader>' }, -- Leader triggers
      { mode = 'x', keys = '<Leader>' },
      { mode = 'n', keys = '\\' },       -- mini.basics
      { mode = 'n', keys = '[' },        -- mini.bracketed
      { mode = 'n', keys = ']' },
      { mode = 'x', keys = '[' },
      { mode = 'x', keys = ']' },
      { mode = 'i', keys = '<C-x>' },    -- Built-in completion
      -- { mode = 'n', keys = 'g' },        -- `g` key (disabled to allow gr for LSP references)
      -- { mode = 'x', keys = 'g' },
      { mode = 'n', keys = "'" },        -- Marks
      { mode = 'n', keys = '`' },
      { mode = 'x', keys = "'" },
      { mode = 'x', keys = '`' },
      { mode = 'n', keys = '"' },        -- Registers
      { mode = 'x', keys = '"' },
      { mode = 'i', keys = '<C-r>' },
      { mode = 'c', keys = '<C-r>' },
      { mode = 'n', keys = '<C-w>' },    -- Window commands
      { mode = 'n', keys = 'z' },        -- `z` key
      { mode = 'x', keys = 'z' },
    },
    -- Delay
    window = {
      delay = 0
    }
  })
end)

later(function()
	require("mini.comment").setup()
end)

later(function()
	-- Customize post-processing of LSP responses for a better user experience.
	-- Don't show 'Text' suggestions (usually noisy) and show snippets last.
	local process_items_opts = { kind_priority = { Text = -1, Snippet = 99 } }
	local process_items = function(items, base)
		return MiniCompletion.default_process_items(items, base, process_items_opts)
	end
	require("mini.completion").setup({
		lsp_completion = {
			-- Without this config autocompletion is set up through `:h 'completefunc'`.
			-- Although not needed, setting up through `:h 'omnifunc'` is cleaner
			-- (sets up only when needed) and makes it possible to use `<C-u>`.
			source_func = "omnifunc",
			auto_setup = false,
			process_items = process_items,
		},
	})

	-- Set 'omnifunc' for LSP completion only when needed.
	local on_attach = function(ev)
		vim.bo[ev.buf].omnifunc = "v:lua.MiniCompletion.completefunc_lsp"
	end
	_G.Config.new_autocmd("LspAttach", nil, on_attach, "Set 'omnifunc'")

	-- Advertise to servers that Neovim now supports certain set of completion and
	-- signature features through 'mini.completion'.
	vim.lsp.config("*", { capabilities = MiniCompletion.get_lsp_capabilities() })
end)

later(function()
	require("mini.diff").setup()
end)

later(function()
	require("mini.git").setup()
end)

later(function()
	local hipatterns = require("mini.hipatterns")
	local hi_words = MiniExtra.gen_highlighter.words
	hipatterns.setup({
		highlighters = {
			-- Highlight a fixed set of common words. Will be highlighted in any place,
			-- not like "only in comments".
			fixme = hi_words({ "FIXME", "Fixme", "fixme" }, "MiniHipatternsFixme"),
			hack = hi_words({ "HACK", "Hack", "hack" }, "MiniHipatternsHack"),
			todo = hi_words({ "TODO", "Todo", "todo" }, "MiniHipatternsTodo"),
			note = hi_words({ "NOTE", "Note", "note" }, "MiniHipatternsNote"),

			-- Highlight hex color string (#aabbcc) with that color as a background
			hex_color = hipatterns.gen_highlighter.hex_color(),
		},
	})
end)

later(function()
	require("mini.indentscope").setup()
end)

later(function()
	require("mini.jump").setup()
end)

later(function()
	require("mini.jump2d").setup()
end)

later(function()
	require("mini.keymap").setup()
	-- Navigate 'mini.completion' menu with `<Tab>` /  `<S-Tab>`
	MiniKeymap.map_multistep("i", "<Tab>", { "pmenu_next" })
	MiniKeymap.map_multistep("i", "<S-Tab>", { "pmenu_prev" })
	-- On `<CR>` try to accept current completion item, fall back to accounting
	-- for pairs from 'mini.pairs'
	MiniKeymap.map_multistep("i", "<CR>", { "pmenu_accept", "minipairs_cr" })
	-- On `<BS>` just try to account for pairs from 'mini.pairs'
	MiniKeymap.map_multistep("i", "<BS>", { "minipairs_bs" })
end)

later(function()
	local map = require("mini.map")
	map.setup({
		-- Use Braille dots to encode text
		symbols = { encode = map.gen_encode_symbols.dot("4x2") },
		-- Show built-in search matches, 'mini.diff' hunks, and diagnostic entries
		integrations = {
			map.gen_integration.builtin_search(),
			map.gen_integration.diff(),
			map.gen_integration.diagnostic(),
		},
	})

	-- Map built-in navigation characters to force map refresh
	for _, key in ipairs({ "n", "N", "*", "#" }) do
		local rhs = key
			-- Also open enough folds when jumping to the next match
			.. "zv"
			.. "<Cmd>lua MiniMap.refresh({}, { lines = false, scrollbar = false })<CR>"
		vim.keymap.set("n", key, rhs)
	end
end)

later(function()
	require("mini.move").setup()
end)

later(function()
	require("mini.operators").setup({
		-- Change replace operator from gr to gR to free gr for LSP references
		replace = { prefix = "gR" },
	})

	-- Create mappings for swapping adjacent arguments. Notes:
	-- - Relies on `a` argument textobject from 'mini.ai'.
	-- - It is not 100% reliable, but mostly works.
	-- - It overrides `:h (` and `:h )`.
	-- Explanation: `gx`-`ia`-`gx`-`ila` <=> exchange current and last argument
	-- Usage: when on `a` in `(aa, bb)` press `)` followed by `(`.
	vim.keymap.set("n", "(", "gxiagxila", { remap = true, desc = "Swap arg left" })
	vim.keymap.set("n", ")", "gxiagxina", { remap = true, desc = "Swap arg right" })
end)

later(function()
	-- Create pairs not only in Insert, but also in Command line mode
	require("mini.pairs").setup({ modes = { command = true } })
end)

later(function()
	-- Define language patterns to work better with 'friendly-snippets'
	local latex_patterns = { "latex/**/*.json", "**/latex.json" }
	local lang_patterns = {
		tex = latex_patterns,
		plaintex = latex_patterns,
		-- Recognize special injected language of markdown tree-sitter parser
		markdown_inline = { "markdown.json" },
	}

	local snippets = require("mini.snippets")
	local config_path = vim.fn.stdpath("config")
	snippets.setup({
		snippets = {
			-- Always load 'snippets/global.json' from config directory
			snippets.gen_loader.from_file(config_path .. "/snippets/global.json"),
			-- Load from 'snippets/' directory of plugins, like 'friendly-snippets'
			snippets.gen_loader.from_lang({ lang_patterns = lang_patterns }),
		},
	})
	-- By default snippets available at cursor are not shown as candidates in
	-- 'mini.completion' menu. This requires a dedicated in-process LSP server
	-- that will provide them. To have that, uncomment next line (use `gcc`).
	MiniSnippets.start_lsp_server()
end)

later(function()
	require("mini.splitjoin").setup()
end)

later(function()
	require("mini.surround").setup()
end)

later(function()
	require("mini.trailspace").setup()
end)

later(function()
	require("mini.visits").setup()
end)
