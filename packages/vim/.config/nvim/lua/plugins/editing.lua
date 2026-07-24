-- General editing utilities, git, and language syntax plugins.
return {
    -- Util -----------------------------------------------------------
    { 'direnv/direnv.vim' },
    -- file browser
    { 'tpope/vim-vinegar' },
    -- get the output of shell commands in a new split buffer
    { 'phodge/vim-shell-command' },
    -- browse the undotree easily (<F2> mapping in config.keymaps)
    { 'mbbill/undotree' },
    -- A better surround plugin
    { 'machakann/vim-sandwich' },
    -- mappings
    { 'tpope/vim-unimpaired' },
    -- repeat macros with .
    { 'tpope/vim-repeat' },
    -- Get the differences between line ranges
    { 'AndrewRadev/linediff.vim' },
    -- easily align things
    { 'godlygeek/tabular' },
    -- navigate tmux splits
    {
        'christoomey/vim-tmux-navigator',
        init = function()
            -- Disable tmux navigator when zooming the Vim pane
            vim.g.tmux_navigator_disable_when_zoomed = 1
        end,
    },
    -- Session management (mostly for making tmux continuum behave better)
    { 'tpope/vim-obsession' },
    {
        'bkad/CamelCaseMotion',
        config = function()
            vim.fn['camelcasemotion#CreateMotionMappings']('<localleader>')
        end,
    },
    -- swap arbitrary windows in a layout
    { 'wesQ3/vim-windowswap' },
    -- Enable fuzzy-finder. Lazy-managed like everything else; --bin drops a
    -- binary inside the plugin dir so nvim is self-sufficient even before
    -- the system fzf (Brewfile/apt/dnf) is installed. The shell integration
    -- uses the system fzf via `fzf --zsh` and never touches this copy.
    { 'junegunn/fzf', build = './install --bin' },
    { 'junegunn/fzf.vim' },
    -- fzf pickers for LSP references/implementations
    { 'ibhagwan/fzf-lua' },

    -- Git ("Slow Plugs") --------------------------------------------------
    { 'tpope/vim-git' },      -- Syntax etc for git
    { 'tpope/vim-fugitive' }, -- :Git commands
    -- indicate changed lines from repo in gutter
    {
        'lewis6991/gitsigns.nvim',
        config = function()
            require('gitsigns').setup()
        end,
    },

    -- Languages ------------------------------------------------------------
    {
        'sheerun/vim-polyglot',
        init = function()
            vim.g.polyglot_disabled = { 'markdown', 'sh', 'python', 'bash', 'lua', 'vim', 'go' }
        end,
    },
    -- Make the python indenting actually work
    {
        'Vimjas/vim-python-pep8-indent',
        init = function()
            vim.g.python_pep_8_indent_max_back_search = 500
        end,
    },
    -- Work with VimL
    { 'ynkdir/vim-vimlparser' },
    { 'dbakker/vim-lint' },
    {
        'pearofducks/ansible-vim',
        init = function()
            vim.g.ansible_extra_keywords_highlight = 1
            vim.g.ansible_name_highlight = 'b'
        end,
    },
    { 'NLKNguyen/c-syntax.vim' },
    { 'freitass/todo.txt-vim' },
    {
        'tpope/vim-markdown',
        init = function()
            vim.g.markdown_folding = 1
            vim.g.markdown_syntax_conceal = 0
            vim.g.markdown_fenced_languages = { 'html', 'python', 'bash=sh' }
        end,
    },
    { 'Glench/Vim-Jinja2-Syntax' },
}
