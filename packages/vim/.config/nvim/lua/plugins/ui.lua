-- Colorscheme, statusline, and visual helpers.
return {
    {
        'ellisonleao/gruvbox.nvim',
        priority = 1000, -- load before everything else so highlights stick
        config = function()
            require('gruvbox').setup({
                undercurl = true,
                underline = true,
                bold = true,
                italic = {
                    strings = false,
                    comments = true,
                    operators = false,
                    folds = true,
                },
                strikethrough = true,
                invert_selection = false,
                invert_signs = false,
                invert_tabline = false,
                invert_intend_guides = false,
                inverse = true, -- invert background for search, diffs, statuslines and errors
                contrast = '', -- can be "hard", "soft" or empty string
                palette_overrides = {},
                overrides = {
                    String = { italic = false },
                    Operator = { italic = false },
                },
                dim_inactive = false,
                transparent_mode = false,
            })

            vim.cmd.colorscheme('gruvbox')
            local macos_mode = vim.env.MACOS_MODE
            if macos_mode == 'dark' or macos_mode == '' or macos_mode == nil then
                vim.o.background = 'dark'
            else
                vim.o.background = 'light'
            end

            vim.cmd('highlight WhitespaceEOL ctermbg=DarkYellow guibg=DarkYellow')

            -- Highlight palettes; functions so :BG can re-apply them after
            -- flipping the background
            vim.cmd([[
function! InterestingWordHighlights()
hi def InterestingWord1 guifg=#000000 ctermfg=16 guibg=#ffa724 ctermbg=214
hi def InterestingWord2 guifg=#000000 ctermfg=16 guibg=#aeee00 ctermbg=154
hi def InterestingWord3 guifg=#000000 ctermfg=16 guibg=#8cffba ctermbg=121
hi def InterestingWord4 guifg=#000000 ctermfg=16 guibg=#b88853 ctermbg=137
hi def InterestingWord5 guifg=#000000 ctermfg=16 guibg=#ff9eb8 ctermbg=211
hi def InterestingWord6 guifg=#000000 ctermfg=16 guibg=#ff2c4b ctermbg=195
endfunction
call InterestingWordHighlights()

function! ALEHighlightColors()
highlight ALEError term=bold,italic gui=bold,italic guibg=#bd1701
highlight ALEStyleError term=italic gui=italic guibg=#bd3601
highlight ALEWarning guibg=#bd7400
highlight ALEStyleWarning guibg=#ec7400
highlight ALEInfo guibg=#008900
endfunction
call ALEHighlightColors()

if exists("*ToggleBackground") == 0
    function ToggleBackground()
        if &background == "dark"
            set background=light
        else
            set background=dark
        endif
    call InterestingWordHighlights()
    call ALEHighlightColors()
    endfunction
    command BG call ToggleBackground()
endif
]])
        end,
    },

    -- the pretty at the bottom of the buffer
    {
        'itchyny/lightline.vim',
        init = function()
            vim.g.lightline = {
                colorscheme = 'PaperColor',
                active = {
                    left = {
                        { 'mode', 'paste' },
                        { 'gitbranch', 'readonly', 'relativepath', 'modified' },
                    },
                    right = {
                        { 'lineinfo' },
                        { 'percent' },
                        { 'fileencoding', 'filetype' },
                        { 'treesitter' },
                    },
                },
                inactive = {
                    left = { { 'relativepath' } },
                    right = { { 'lineinfo' }, { 'percent' } },
                },
                component_function = {
                    gitbranch = 'FugitiveHead',
                    treesitter = 'nvim_treesitter#statusline',
                },
                mode_map = {
                    n = 'N',
                    i = 'I',
                    R = 'R',
                    v = 'V',
                    V = 'VL',
                    [vim.keycode('<C-v>')] = 'VB',
                    c = 'C',
                    s = 'S',
                    S = 'SL',
                    [vim.keycode('<C-s>')] = 'SB',
                    t = 'T',
                },
            }
        end,
        config = function()
            -- :LightlineColorscheme <name> switches the statusline theme.
            -- (the old s:-scoped helpers got global names to survive
            -- outside a vimscript file's script scope)
            vim.cmd([[
function! LightlineSetColorscheme(name) abort
  let g:lightline.colorscheme = a:name
  call lightline#init()
  call lightline#colorscheme()
  call lightline#update()
endfunction

function! LightlineColorschemes(...) abort
  return join(map(
        \ globpath(&rtp,"autoload/lightline/colorscheme/*.vim",1,1),
        \ "fnamemodify(v:val,':t:r')"),
        \ "\n")
endfunction

command! -nargs=1 -complete=custom,LightlineColorschemes LightlineColorscheme
      \ call LightlineSetColorscheme(<q-args>)
]])
        end,
    },

    -- For presentations
    { 'NLKNguyen/papercolor-theme' },

    -- See indentation as highlights
    {
        'nathanaelkane/vim-indent-guides',
        init = function()
            vim.g.indent_guides_auto_colors = 1
            vim.g.indent_guides_guide_size = 0
            vim.g.indent_guides_start_level = 1
            vim.g.indent_guides_autocmds_enabled = 1
            vim.g.indent_guides_enable_on_vim_startup = 1
            vim.g.indent_guides_exclude_filetypes = { 'shell-command', 'terminal', 'man' }
        end,
    },

    -- Rainbows for all the brackets, makes it easier to see mismatches
    {
        'luochen1990/rainbow',
        init = function()
            vim.g.rainbow_active = 1
            vim.g.rainbow_conf = {
                separately = {
                    go = 0,
                },
            }
        end,
    },
}
