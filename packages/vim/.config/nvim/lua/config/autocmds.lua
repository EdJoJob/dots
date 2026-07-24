-- Autocmds ported from the old ~/.vimrc.  Per-filetype option blocks moved
-- to after/ftplugin/<ft>.lua; what remains either isn't a FileType autocmd
-- or must keep its definition order relative to the plugin specs.

local function aug(name)
    return vim.api.nvim_create_augroup(name, { clear = true })
end
local au = vim.api.nvim_create_autocmd

-- Re-source the config on write (was: BufWritePost .vimrc source %).
-- lazy.nvim tolerates a re-:source with a warning, as re-running plug did.
local config_init = vim.fn.stdpath('config') .. '/init.lua'
local init_patterns = { config_init }
local real_init = vim.uv.fs_realpath(config_init)
if real_init and real_init ~= config_init then
    table.insert(init_patterns, real_init)
end
au('BufWritePost', {
    group = aug('MY_VIMRC'),
    pattern = init_patterns,
    command = 'source %',
})

-- Rebuild binary spell files when the word lists are written
au('BufWritePost', {
    group = aug('PERSONAL_SPELL_FILES'),
    pattern = {
        vim.fn.stdpath('config') .. '/spell/en.utf-8.add',
        vim.fn.expand('~/.vimspell.add'),
    },
    command = 'silent mkspell! %',
})

-- ANSIBLE: kept as a FileType autocmd because the dotted "yaml.ansible"
-- pattern must keep its original matching semantics
local ansible = aug('PERSONAL_ANSIBLE')
au({ 'BufNewFile', 'BufRead' }, {
    group = ansible,
    pattern = '*ansible/*.yml',
    command = 'setlocal filetype=yaml.ansible',
})
au('FileType', {
    group = ansible,
    pattern = 'yaml.ansible',
    command = 'setlocal shiftwidth=2 tabstop=2 softtabstop=2 shiftround expandtab autoindent foldmethod=indent',
})

-- Java: keep long files highlighting correctly
au({ 'BufEnter', 'BufRead' }, {
    group = aug('PERSONAL_JAVA'),
    pattern = '*.java',
    command = 'syntax sync fromstart',
})

-- open python wheels like zip files
au('BufReadCmd', {
    group = aug('PERSONAL_PYTHON'),
    pattern = '*.whl',
    command = 'call zip#Browse(expand("<amatch>"))',
})

-- Vim: stays an autocmd (not ftplugin) so it keeps firing BEFORE the
-- treesitter FileType callback defined during plugin setup -- treesitter's
-- foldmethod=expr must win for vim files, as it always has
au('FileType', {
    group = aug('PERSONAL_VIM'),
    pattern = 'vim',
    command = 'setlocal foldmethod=marker iskeyword+=:',
})

-- terminal
local term = aug('PERSONAL_TERMINAL')
au('TermOpen', { group = term, pattern = 'term://*', command = 'setlocal colorcolumn=' })
au('TermOpen', { group = term, pattern = 'term://*', command = 'setlocal nonumber' })
au('TermOpen', { group = term, pattern = 'term://*', command = 'IndentGuidesDisable' })
au('TermOpen', { group = term, pattern = 'term://*', command = 'startinsert' })

-- Only show cursorline in the current window and in normal mode
local cline = aug('cline')
au({ 'WinLeave', 'InsertEnter' }, { group = cline, command = 'set nocursorline' })
au({ 'WinEnter', 'InsertLeave' }, { group = cline, command = 'set cursorline' })

-- Make sure Vim returns to the same line when you reopen a file
au('BufReadPost', {
    group = aug('line_return'),
    command = [[if line("'\"") > 0 && line("'\"") <= line("$") | execute 'normal! g`"zvzz' | endif]],
})

-- Highlight end of line whitespace
vim.cmd('highlight EOLWS ctermbg=red guibg=red')
local ws = aug('PERSONAL_WHITESPACE')
au('InsertEnter', { group = ws, command = [[syn clear EOLWS | syn match EOLWS excludenl /\s\+\%#\@!$/]] })
au('InsertLeave', { group = ws, command = [[syn clear EOLWS | syn match EOLWS excludenl /\s\+$/]] })

-- Highlight TODO, FIXME, NOTE, etc.
local todo = aug('PERSONAL_TODO_HIGHLIGHT')
au('Syntax', { group = todo, command = [[call matchadd('Todo',  '\W\zs\(TODO\|FIXME\|CHANGED\|XXX\|BUG\|HACK\):')]] })
au('Syntax', { group = todo, command = [[call matchadd('Debug', '\W\zs\(NOTE\|INFO\|IDEA\):')]] })

-- Resize splits when the window is resized
au('VimResized', { group = aug('PERSONAL_RESIZE'), command = 'wincmd =' })
