-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

--Remap kj, ctrl+g as escape key
vim.keymap.set("i", "kj", "<esc>", { noremap = true })
vim.keymap.set("c", "kj", "<esc>", { noremap = true })
vim.keymap.set("i", "<C-g>", "<esc>", { noremap = true })
vim.keymap.set("c", "<C-g>", "<esc>", { noremap = true })

-- when replacing the repcaled item gets in the keyboard no i dont want that
vim.keymap.set({ "n", "x", "o" }, "<leader>p", '"_dP')

-- org like updown of selected region more visual
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
