-- Neovim configuration entry point.
--
--   lua/config/{options,keymaps,autocmds}.lua   core editor setup
--   lua/plugins/*.lua                           lazy.nvim plugin specs
--   after/ftplugin/*                            per-filetype settings

-- Leader keys, before any mappings are created.  mapleader stays at the
-- default backslash; set it explicitly so it never depends on load order.
vim.g.mapleader = '\\'
vim.g.maplocalleader = '|'

require('config.options')
require('config.keymaps')
require('config.autocmds')

-- Bootstrap lazy.nvim ---------------------------------------------------{{{
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local out = vim.fn.system({
        'git', 'clone', '--filter=blob:none',
        'https://github.com/folke/lazy.nvim.git', '--branch=stable', lazypath,
    })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { 'Failed to clone lazy.nvim:\n', 'ErrorMsg' },
            { out, 'WarningMsg' },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)
-- }}}

-- Keep the lockfile in the dotfiles repo: stow deploys this file as a
-- per-file symlink, so resolving init.lua's real path lands in the repo and
-- lazy-lock.json is written (and committed) next to it.  An unstowed
-- checkout falls back to the config dir itself.
local init_path = vim.fn.stdpath('config') .. '/init.lua'
local lockfile = vim.fs.joinpath(
    vim.fs.dirname(vim.uv.fs_realpath(init_path) or init_path),
    'lazy-lock.json'
)

require('lazy').setup({
    spec = { { import = 'plugins' } },
    -- vim-plug loaded everything at startup; keep that behaviour rather
    -- than auditing every plugin for lazy-load safety.
    defaults = { lazy = false },
    lockfile = lockfile,
    install = { colorscheme = { 'gruvbox' } },
    rocks = { enabled = false },
    change_detection = { notify = false },
})

-- Machine-local extras ---------------------------------------------------
local local_vimrc = vim.fn.expand('~/.local_vimrc')
if vim.fn.filereadable(local_vimrc) == 1 then
    vim.cmd.source(local_vimrc)
end
if vim.env.EXTRA_VIM then
    for _, path in ipairs(vim.split(vim.env.EXTRA_VIM, ':')) do
        vim.cmd.source(path)
    end
end
