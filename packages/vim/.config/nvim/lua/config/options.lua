-- Core options and plugin-free g: variables, ported from the old ~/.vimrc.

local opt = vim.opt

-- Providers ------------------------------------------------------------
vim.g.python3_host_prog = '~/.local/neovim/bin/python3'

-- Basic ----------------------------------------------------------------
opt.title = true                 -- set the title of the terminal window
vim.o.titlestring = 'VIM (%f) %t' -- For Talon filetype detection
opt.laststatus = 2               -- always show the statusline
vim.cmd('set t_Co=256')          -- accepted-but-ignored by nvim; kept from vim
opt.splitbelow = true            -- new splits at bottom
opt.splitright = true            -- new splits at right
opt.mouse = 'a'
opt.fillchars:append({ vert = '█' })
opt.backspace = '2'              -- backspace over everything
opt.selectmode = ''              -- don't use select mode
opt.cmdheight = 2                -- show lots of space for the commandline
opt.showcmd = true               -- show incomplete commands
opt.history = 1000               -- lots of command history
opt.lazyredraw = true            -- don't redraw the screen when executing macros
opt.matchtime = 3                -- faster bracket matching
opt.timeoutlen = 500
opt.ttimeoutlen = 0              -- give me time to complete mappings
opt.foldlevelstart = 99
opt.relativenumber = true
opt.number = true
opt.numberwidth = 1
opt.cursorline = true            -- highlight the current line
opt.wildmode = 'longest:full'    -- make cmdline tab completion similar to bash
opt.wildmenu = true              -- enable ctrl-n and ctrl-p to scroll thru matches
opt.wildignore:append({ '*.o', '*.obj', '*~' }) -- stuff to ignore when tab completing
opt.wildignore:append([[.\s+]])
opt.scrolloff = 5                -- keep this number of lines on the screen when scrolling vertically
opt.colorcolumn = '80,100'
opt.suffixes:append({ '.pyc', '.pyo', '.class' })
-- Not used as I have lightline (would pair with 'ruler')
opt.rulerformat = [[%55(%{strftime('%a %b %e %I:%M %p')} %5l,%-6(%c%V%) %P%)]]

-- Formatting -------------------------------------------------------------
opt.list = false                 -- show spacer characters (off)
opt.listchars = { tab = '▸ ', eol = '¬', extends = '❯', precedes = '❮', trail = '·' }
opt.linebreak = true             -- wrap lines at &breakat when nolist
opt.showbreak = '↳'              -- leader for linebreak lines
opt.breakindent = true
opt.breakindentopt = 'shift:2'
opt.smarttab = true
opt.expandtab = true
opt.softtabstop = 4
opt.shiftwidth = 4
opt.tabstop = 4
opt.wrap = true
opt.formatoptions:append('q')    -- format comments
opt.formatoptions:append('r')    -- insert comment header after enter in insert
opt.formatoptions:append('n')    -- recognize numbered lists
opt.formatoptions:append('1')    -- don't break a line on a 1 letter word, rather break before it
opt.formatoptions:append('l')    -- long lines in insert mode are not broken
opt.formatoptions:append('j')    -- when joining comment lines, remove comment leader

-- Spelling ---------------------------------------------------------------
opt.dictionary = '/usr/share/dict/words'
opt.spelllang = 'en_au'
opt.spell = false
opt.spellfile = vim.fn.expand('~/.vimspell.add')
    .. ',' .. vim.fn.stdpath('config') .. '/spell/en.utf-8.add'

-- Backups ------------------------------------------------------------------
opt.backup = true                -- enable backups
local state_dir = vim.fn.stdpath('state')
opt.undodir = state_dir .. '/undo//'    -- undo files
opt.undofile = true
opt.backupdir = state_dir .. '/backup//' -- backups
opt.directory = state_dir .. '/swap//'   -- swap files
-- Make those folders automatically if they don't already exist.
for _, dir in ipairs({ vim.o.undodir, vim.o.backupdir, vim.o.directory }) do
    if vim.fn.isdirectory(dir) == 0 then
        vim.fn.mkdir(dir, 'p')
    end
end

-- Search ---------------------------------------------------------------
opt.ignorecase = true
opt.smartcase = true
opt.gdefault = true
opt.incsearch = true
opt.showmatch = true
opt.hlsearch = true

-- GUI --------------------------------------------------------------------
vim.o.guifont = 'Liberation Mono for Powerline 8'
-- no scrollbars or toolbar (ignored by nvim TUI, kept for GUIs)
vim.cmd([[
set guioptions-=r
set guioptions-=R
set guioptions-=l
set guioptions-=L
set guioptions-=T
]])

-- Colours (terminal codes; accepted-but-ignored by nvim) -------------------
vim.cmd('set t_ZH=\27[3m')
vim.cmd('set t_ZR=\27[23m')
if vim.fn.exists('&t_8f') == 1 and vim.fn.exists('&t_8b') == 1 then
    vim.cmd([[let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"]])
    vim.cmd([[let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"]])
end
opt.termguicolors = true

-- Builtin syntax/plugin knobs ------------------------------------------
vim.g.sh_fold_enabled = 7        -- fold sh functions, heredocs and if/do/for
vim.g.python_highlight_all = 1
vim.g.netrw_liststyle = 0        -- get tree-style listing

-- Relics kept from the old vimrc (their plugins are not currently
-- installed, but they are harmless and were always set) ------------------
vim.g.airline_theme = 'base16_gruvbox_dark_medium'
vim.g.LatexBox_build_dir = 'build'
vim.g.dokumentary_docprgs = { python = '' }
vim.g.go_highlight_types = 1
vim.g.go_highlight_fields = 1
vim.g.go_highlight_functions = 1
vim.g.go_highlight_function_calls = 1
vim.g.go_highlight_operators = 1
vim.g.go_highlight_extra_types = 1
vim.g.go_highlight_build_constraints = 1
vim.g.go_highlight_generate_tags = 1

-- Folding ----------------------------------------------------------------
-- FoldText stays vimscript: it leans on redir/sign parsing and exact
-- string arithmetic that gains nothing from a lua port.
vim.cmd([[
function! FoldText()
    let l:lpadding = &fdc
    redir => l:signs
    execute 'silent sign place buffer='.bufnr('%')
    redir End
    let l:lpadding += l:signs =~? 'id=' ? 2 : 0

    if exists('+relativenumber')
        if (&number)
            let l:lpadding += max([&numberwidth, strlen(line('$'))]) + 1
        elseif (&relativenumber)
            " change to 3 as rare to have more than 99 lines on the screen
            let l:lpadding += max([&numberwidth, 3])
        endif
    else
        if (&number)
            let l:lpadding += max([&numberwidth, strlen(line('$'))]) + 1
        endif
    endif

    " expand tabs
    let l:start = substitute(getline(v:foldstart), '\t', repeat(' ', &tabstop), 'g')
    let l:end = substitute(substitute(getline(v:foldend), '\t', repeat(' ', &tabstop), 'g'), '^\s*', '', 'g')

    let l:info = ' (' . (v:foldend - v:foldstart) . ')'
    let l:infolen = strlen(substitute(l:info, '.', 'x', 'g'))
    let l:width = winwidth(0) - l:lpadding - l:infolen

    let l:separator = ' … '
    let l:separatorlen = strlen(substitute(l:separator, '.', 'x', 'g'))
    let l:end = strpart(l:end , 0, l:width - strlen(substitute(l:start, '.', 'x', 'g')) - l:separatorlen)
    let l:text = l:start . ' … ' . l:end

    return l:text . repeat(' ', l:width - strlen(substitute(l:text, '.', 'x', 'g'))) . l:info
endfunction
]])
opt.foldtext = 'FoldText()'

-- Get the name of the current tmux session (kept for local/extra configs)
vim.cmd([[
function! TmuxSessionName()
    if (exists("$TMUX"))
        return system('tmux display-message -p "#S"')
    endif
    return ''
endfunction
]])
