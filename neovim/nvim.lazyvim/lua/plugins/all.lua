return {
  {
    "vhyrro/luarocks.nvim",
    priority = 1000,
    config = true,
    opts = {
      rocks = { "lua-curl", "nvim-nio", "mimetypes", "xml2lua" },
    },
  },
  -- Copilot
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    build = ":Copilot auth",
    opts = {
      suggestion = { enabled = false },
      panel = { enabled = false },
      filetypes = {
        markdown = true,
        help = true,
      },
    },
  },

  {
    "neovim/nvim-lspconfig",
    dependencies = {
      { "rafi/neoconf-venom.nvim" },
    },
    opts = function(_, opts)
      require("venom").setup()
    end,
  },

  {
    "rafi/neoconf-venom.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "folke/neoconf.nvim" },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "ninja", "python", "rst", "toml" })
      end
    end,
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {},
        ruff_lsp = {},
      },
    },
    setup = {
      ruff_lsp = function()
        require("lazyvim.util").on_attach(function(client, _)
          if client.name == "ruff_lsp" then
            -- Disable hover in favor of Pyright
            client.server_capabilities.hoverProvider = false
          end
        end)
      end,
    },
  },

  {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = {
      "nvim-neotest/neotest-python",
    },
    opts = {
      adapters = {
        ["neotest-python"] = {
          -- Here you can specify the settings for the adapter, i.e.
          runner = "pytest",
          -- python = ".venv/bin/python",
        },
      },
    },
  },

  {
    "nvim-neotest/neotest-python",
  },

  {
    "linux-cultist/venv-selector.nvim",
    cmd = "VenvSelect",
    opts = { name = ".venv", dap_enabled = true },
    keys = { { "<leader>cv", "<cmd>:VenvSelect<cr>", desc = "Select VirtualEnv" } },
  },

  {
    "ahmedkhalf/project.nvim",
    opts = {},
    event = "VeryLazy",
    config = function(_, opts)
      require("project_nvim").setup(opts)
      require("telescope").load_extension("projects")
    end,
    keys = {
      { "<leader>fp", "<Cmd>Telescope projects<CR>", desc = "Projects" },
    },
  },

  --lualine
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    event = "VeryLazy",
    opts = function(_, opts)
      local Util = require("lazyvim.util").ui
      local colors = {
        [""] = Util.fg("Special"),
        ["Normal"] = Util.fg("Special"),
        ["Warning"] = Util.fg("DiagnosticError"),
        ["InProgress"] = Util.fg("DiagnosticWarn"),
      }
      table.insert(opts.sections.lualine_x, 2, {
        function()
          local icon = require("lazyvim.config").icons.kinds.Copilot
          local status = require("copilot.api").status.data
          return icon .. (status.message or "")
        end,
        cond = function()
          local ok, clients = pcall(vim.lsp.get_active_clients, { name = "copilot", bufnr = 0 })
          return ok and #clients > 0
        end,
        color = function()
          if not package.loaded["copilot"] then
            return
          end
          local status = require("copilot.api").status.data
          return colors[status.status] or colors[""]
        end,
      })
    end,
  },

  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      defaults = {
        ["<leader>d"] = { name = "+debug" },
        ["<leader>da"] = { name = "+adapters" },
      },
    },
  },

  {
    "akinsho/toggleterm.nvim",
    cmd = "ToggleTerm",
    keys = {
      {
        "<C-\\>",
        mode = { "n", "t" },
        silent = true,
        function()
          local venv = vim.b["virtual_env"]
          local term = require("toggleterm.terminal").Terminal:new({
            env = venv and { VIRTUAL_ENV = venv } or nil,
            count = vim.v.count > 0 and vim.v.count or 1,
          })
          term:toggle()
        end,
        desc = "Toggle terminal",
      },
    },
    opts = {
      open_mapping = false,
    },
  },

  { "ThePrimeagen/vim-be-good" },

  {
    "TimUntersberger/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
    },
    keys = {
      {
        "<leader>g",
        [[<cmd>lua require('neogit').open()<CR>]],
        noremap = true,
        silent = true,
      },
      {
        "<C-x>g",
        [[<cmd>lua require('neogit').open()<CR>]],
        mode = "i",
        noremap = true,
        silent = true,
      },
      {
        "<C-x>g",
        [[<cmd>lua require('neogit').open()<CR>]],
        noremap = true,
        silent = true,
      },
    },
    opts = {
      disable_signs = false,
      disable_hint = false,
      disable_context_highlighting = false,
      disable_commit_confirmation = false,
      auto_refresh = true,
      disable_builtin_notifications = false,
      commit_popup = {
        kind = "split",
      },
      -- Change the default way of opening neogit
      kind = "tab",
      -- customize displayed signs
      signs = {
        -- { CLOSED, OPENED }
        section = { ">", "v" },
        item = { ">", "v" },
        hunk = { "", "" },
      },
      integrations = {
        -- Neogit only provides inline diffs. If you want a more traditional way to look at diffs, you can use `sindrets/diffview.nvim`.
        -- The diffview integration enables the diff popup, which is a wrapper around `sindrets/diffview.nvim`.
        --
        -- Requires you to have `sindrets/diffview.nvim` installed.
        -- use {
        --   'TimUntersberger/neogit',
        --   requires = {
        --     'nvim-lua/plenary.nvim',
        --     'sindrets/diffview.nvim'
        --   }
        -- }
        --
        diffview = false,
      },
      -- Setting any section to `false` will make the section not render at all
      sections = {
        untracked = {
          folded = false,
        },
        unstaged = {
          folded = false,
        },
        staged = {
          folded = false,
        },
        stashes = {
          folded = true,
        },
        unpulled = {
          folded = true,
        },
        unmerged = {
          folded = false,
        },
        recent = {
          folded = true,
        },
      },
      -- override/add mappings
      mappings = {
        -- modify status buffer mappings
        status = {
          -- Adds a mapping with "B" as key that does the "BranchPopup" command
          ["B"] = "BranchPopup",
          -- Removes the default mapping of "s"
          ["s"] = "",
        },
      },
    },
  },

  --harpoon baby
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function(_, opts)
      local harpoon = require("harpoon")
      harpoon:setup()

      -- basic telescope configuration
      require("telescope").load_extension("harpoon")
      local conf = require("telescope.config").values
      local function toggle_telescope(harpoon_files)
        local file_paths = {}
        for _, item in ipairs(harpoon_files.items) do
          table.insert(file_paths, item.value)
        end

        require("telescope.pickers")
          .new({}, {
            prompt_title = "Harpoon",
            finder = require("telescope.finders").new_table({
              results = file_paths,
            }),
            previewer = conf.file_previewer({}),
            sorter = conf.generic_sorter({}),
          })
          :find()
      end
      vim.keymap.set("n", "<leader>hm", function()
        toggle_telescope(harpoon:list())
      end, { desc = "Open harpoon window" })
    end,
    keys = {
      {
        "<leader>ha",
        function()
          require("harpoon"):list():add()
        end,
        desc = "[H]arpoon [A]dd",
      },
      {
        "<leader>hf",
        function()
          local harpoon = require("harpoon")
          harpoon.ui:toggle_quick_menu(harpoon:list())
        end,
        desc = "[H]arpoon [M]menu",
      },
      {
        "<leader>hp",
        function()
          require("harpoon"):list():prev()
        end,
        desc = "[H]arpoon [P]rev File",
      },
      {
        "<leader>hn",
        function()
          require("harpoon"):list():next()
        end,
        desc = "[H]arpoon [N]ext File",
      },
      {
        "<leader>h1",
        function()
          return require("harpoon"):list():select(1)
        end,
        desc = "[H]arpoon File [1]",
      },
      {
        "<leader>h2",
        function()
          return require("harpoon"):list():select(2)
        end,
      },
      {
        "<leader>h3",
        function()
          return require("harpoon"):list():select(3)
        end,
      },
      {
        "<leader>h4",
        function()
          return require("harpoon"):list():select(4)
        end,
      },
      {
        "<leader>h5",
        function()
          return require("harpoon"):list():select(5)
        end,
      },
      {
        "<leader>h6",
        function()
          return require("harpoon"):list():select(6)
        end,
      },
      {
        "<leader>h7",
        function()
          return require("harpoon"):list():select(7)
        end,
      },
      {
        "<leader>h8",
        function()
          return require("harpoon"):list():select(8)
        end,
      },
    },
  },

  -- Lua
  {
    "folke/zen-mode.nvim",
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    },
  },
  {
    "mfussenegger/nvim-lint",
    init = function()
      require("lint").linters.golangcilint.args = {
        "--module-download-mode=vendor",
      }
    end,
    opts = {
      linters_by_ft = {
        go = { "golangcilint" },
      },
    },
  },
}
