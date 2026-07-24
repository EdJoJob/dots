-- Global mappings.  Plugin-buffer-local maps live in LspAttach or plugin
-- specs; per-filetype maps live in after/ftplugin/.
--
-- map('', ...) is nnoremap+vnoremap+onoremap, matching the old :noremap.

local map = vim.keymap.set

-- Quick editing ---------------------------------------------------------
local config_init = vim.fn.stdpath('config') .. '/init.lua'
map('n', '<leader>ev', ':tabedit ' .. config_init .. '<cr>')
map('n', '<leader>sv', ':source $MYVIMRC<cr>')
map('n', '<leader>ez', ':tabedit ~/.zshrc<cr>')
map('n', '<leader>es', ':tabedit ' .. vim.fn.stdpath('config') .. '/spell/en.utf-8.add<cr>:vsplit ~/.vimspell.add<cr>')

-- Search ------------------------------------------------------------------
map('n', '/', [[/\v]])
map('v', '/', [[/\v]])
map('n', '<leader><space>', ':noh<cr>:call clearmatches()<cr>:IndentGuidesEnable<cr>', { silent = true })
-- Open a Quickfix window for the last search.
map('n', '<leader>/', [[:execute 'vimgrep /'.@/.'/gj %'<CR>:copen<CR>]], { silent = true })

-- Folding -----------------------------------------------------------------
-- "Focus" the current line: close all folds, open just the folds
-- containing the current line, move it a bit above centre.  Wipes out the
-- z mark, which I never use.  (I use :sus for backgrounding Vim.)
map('n', '<c-z>', 'mzzMzvzz15<c-e>`z')
map('n', '<space>', 'za')

-- Terminal ----------------------------------------------------------------
-- Double esc in term to get to normal mode
map('t', '<Esc><Esc>', [[<C-\><C-n>]])

-- Moving blocks -------------------------------------------------------------
map('v', '<', '<gv')
map('v', '>', '>gv')

-- make Y work more like D and C
map('n', 'Y', 'y$')

-- move up and down screen lines rather than file lines
map('n', 'j', 'gj')
map('n', 'k', 'gk')
map('', 'gj', 'j')
map('', 'gk', 'k')

-- switch tick and inv comma as going back to actual position is far more useful
map('', '`', "'")
map('', "'", '`')

-- dp and do automatically jump to the next change
map('n', 'dp', 'dp]c', { silent = true })
map('n', 'do', 'do]c', { silent = true })

-- Source selection / line of vimscript
map('v', '<leader>S', [[y:execute @@<cr>:echo 'Sourced selection.'<cr>]])
map('n', '<leader>S', [[^vg_y:execute @@<cr>:echo 'Sourced line.'<cr>]])

-- Get all TODO tags in files above current directory
map('', '<Leader>to', [[:Rg! '\b(TODO|FIXME|CHANGED|XXX|BUG|HACK|NOTE|INFO|IDEA)\b' <CR>]])
map('', '<Leader>ti', [[:Rg! \b(TODO|FIXME|CHANGED|XXX|BUG|HACK|NOTE|INFO|IDEA\) % <CR>]])

-- Select (charwise) the contents of the current line, excluding indentation.
-- Great for pasting Python lines into REPLs.
map('n', 'vv', '^vg_')

-- Sudo to write
vim.cmd('cabbr w!! w !sudo tee % >/dev/null')

-- Don't move on *
map('n', '*', [[:let stay_star_view = winsaveview()<cr>*:call winrestview(stay_star_view)<cr>]], { silent = true })

-- Keep search matches in the middle of the window.
map('n', 'n', 'nzzzv')
map('n', 'N', 'Nzzzv')

-- Same when jumping around
map('n', 'g;', 'g;zz')
map('n', 'g,', 'g,zz')
map('n', '<c-o>', '<c-o>zz')

-- Easier to type, and I never use the default behaviour.
map('', 'H', '^')
map('', 'L', '$')
map('v', 'L', 'g_')

-- List navigation -------------------------------------------------------
map('n', '<left>', ':cprev<cr>zvzz')
map('n', '<right>', ':cnext<cr>zvzz')
map('n', '<up>', ':lprev<cr>zvzz')
map('n', '<down>', ':lnext<cr>zvzz')

-- Commenting ------------------------------------------------------------
-- nerdcommenter muscle-memory shims onto the built-in gc operator.  All
-- three toggle: the builtin has no comment-only/uncomment-only variants.
map('n', '<leader>c<space>', 'gcc', { remap = true })
map('x', '<leader>c<space>', 'gc', { remap = true })
map('n', '<leader>cc', 'gcc', { remap = true })
map('x', '<leader>cc', 'gc', { remap = true })
map('n', '<leader>cu', 'gcc', { remap = true })
map('x', '<leader>cu', 'gc', { remap = true })

-- Plugin commands -----------------------------------------------------------
map('n', '<c-p>', ':Files<cr>')            -- fzf.vim
map('n', '<F2>', ':UndotreeToggle<CR>')    -- undotree

-- MiniPlugins ---------------------------------------------------------{{{
-- Highlight Word: <leader>1-6 temporarily highlight the current word in a
-- specific colour (colours defined next to the colorscheme in plugins/ui).
-- Tag jumps: <c-]> jumps to tags and <c-\> opens the tag in a new split,
-- both centering and pulsing the destination line.
-- Kept as vimscript: normal!-heavy, and the exact behaviour matters more
-- than the dialect.  (s:Pulse was renamed PulseCursorLine to survive
-- outside a vimscript file's script scope.)
vim.cmd([[
function! HiInterestingWord(n)
    " Save our location.
    normal! mz

    " Yank the current word into the z register.
    normal! "zyiw

    " Calculate an arbitrary match ID.  Hopefully nothing else is using it.
    let mid = 86750 + a:n

    " Clear existing matches, but don't worry if they don't exist.
    silent! call matchdelete(mid)

    " Construct a literal pattern that has to match at boundaries.
    let pat = '\V\<' . escape(@z, '\') . '\>'

    " Actually match the words.
    call matchadd('InterestingWord' . a:n, pat, 1, mid)

    " Move back to our original location.
    normal! `z
endfunction

nnoremap <silent> <leader>1 :call HiInterestingWord(1)<cr>
nnoremap <silent> <leader>2 :call HiInterestingWord(2)<cr>
nnoremap <silent> <leader>3 :call HiInterestingWord(3)<cr>
nnoremap <silent> <leader>4 :call HiInterestingWord(4)<cr>
nnoremap <silent> <leader>5 :call HiInterestingWord(5)<cr>
nnoremap <silent> <leader>6 :call HiInterestingWord(6)<cr>

function! JumpToTag()
    execute "normal! \<c-]>mzzvzz15\<c-e>"
    execute 'keepjumps normal! `z'
    Pulse
endfunction
function! JumpBackTag(count)
    execute a:count "normal!\<c-t>mzzvzz15\<c-e>"
    execute 'keepjumps normal! `z'
    Pulse
endfunction
function! JumpToTagInSplit()
    execute "normal! \<c-w>v\<c-]>mzzMzvzz15\<c-e>"
    execute 'keepjumps normal! `z'
    Pulse
endfunction
nnoremap <silent><c-]> :silent! call JumpToTag()<cr>
nnoremap <c-t> :call JumpBackTag(v:count1)<cr>
nnoremap <silent><c-\> :silent! call JumpToTagInSplit()<cr>

function! PulseCursorLine()
    redir => old_hi
    silent execute 'hi CursorLine'
    redir END
    let old_hi = split(old_hi, '\n')[0]
    let old_hi = substitute(old_hi, 'xxx', '', '')

    let steps = 4
    let width = 1
    let start = width
    let end = steps * width
    let color = 233

    for i in range(start, end, width)
        execute 'hi CursorLine ctermbg=' . (color + i)
        redraw
        sleep 6m
    endfor
    for i in range(end, start, -1 * width)
        execute 'hi CursorLine ctermbg=' . (color + i)
        redraw
        sleep 6m
    endfor

    execute 'hi ' . old_hi
endfunction
command! -nargs=0 Pulse call PulseCursorLine()
]])
-- }}}
