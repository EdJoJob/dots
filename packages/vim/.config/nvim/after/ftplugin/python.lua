-- (the isort mapping lives in after/ftplugin/python/python.vim)
vim.opt_local.textwidth = 79   -- lines longer than 79 columns will be broken
vim.opt_local.shiftwidth = 4   -- operation >> indents 4 columns; << unindents 4 columns
vim.opt_local.tabstop = 4      -- a hard TAB displays as 4 columns
vim.opt_local.expandtab = true -- insert spaces when hitting TABs
vim.opt_local.softtabstop = 4  -- insert/delete 4 spaces when hitting a TAB/BACKSPACE
vim.opt_local.shiftround = true -- round indent to multiple of 'shiftwidth'
vim.opt_local.autoindent = true -- align the new line indent with the previous line
