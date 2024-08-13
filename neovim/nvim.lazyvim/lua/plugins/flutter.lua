return {
  "akinsho/flutter-tools.nvim",
  lazy = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "stevearc/dressing.nvim", -- optional for vim.ui.select
  },
  config = function(_, opts)
    require("telescope").load_extension("flutter")
  end,
  keys = {
    {
      "<leader>df",
      function()
        require("telescope").extensions.flutter.commands()
      end,
      desc = "Flutter Tools",
    },
  },
  opts = {
    widget_guides = {
      enabled = false,
    },
    lsp = {
      settings = {
        lineLength = 100,
      },
    },
  },
}
