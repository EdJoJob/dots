-- Treesitter (main branch API: setup{install_dir}/install{}), textobjects
-- and treesitter-driven highlights.
return {
    {
        'nvim-treesitter/nvim-treesitter',
        branch = 'main',
        build = ':TSUpdate',
        config = function(plugin)
            -- The main branch keeps its query/runtime files under runtime/,
            -- which is not added to &rtp automatically
            local plugin_runtime = plugin.dir .. '/runtime'
            if vim.fn.isdirectory(plugin_runtime) == 1 then
                vim.opt.runtimepath:prepend(plugin_runtime)
            end

            -- Parsers live outside the plugin dir so they survive plugin
            -- reinstalls and stay per-OS
            local treesitter_parser_dir = vim.fn.expand(
                '~/.local/nvim-treesitter-parsers/' .. vim.uv.os_uname().sysname
            )
            require('nvim-treesitter').setup({
                install_dir = treesitter_parser_dir,
            })
            require('nvim-treesitter').install({
                'bash',
                'go',
                'gomod',
                'gosum',
                'lua',
                'python',
                'markdown',
                'markdown_inline',
                'vim',
                'vimdoc',
            })
            vim.api.nvim_create_autocmd('FileType', {
                pattern = { 'bash', 'go', 'lua', 'python', 'markdown', 'vim' },
                callback = function(ctx)
                    -- Disable vim syntax to let treesitter handle highlighting
                    vim.bo[ctx.buf].syntax = ''
                    -- Start treesitter highlighting
                    vim.treesitter.start(ctx.buf)
                    -- Enable treesitter indenting
                    vim.bo[ctx.buf].indentexpr = 'v:lua.vim.treesitter.indentexpr()'
                    -- Enable treesitter folds
                    vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
                    vim.wo.foldmethod = 'expr'
                end,
            })
        end,
    },

    -- function/class text objects (main branch matches nvim-treesitter main)
    {
        'nvim-treesitter/nvim-treesitter-textobjects',
        branch = 'main',
        dependencies = { 'nvim-treesitter/nvim-treesitter' },
        config = function()
            require('nvim-treesitter-textobjects').setup({
                select = {
                    lookahead = true,
                },
            })

            -- function/class text objects (previously coc documentSymbol based)
            local select_textobjects = {
                ['if'] = '@function.inner',
                ['af'] = '@function.outer',
                ['ic'] = '@class.inner',
                ['ac'] = '@class.outer',
            }
            for lhs, capture in pairs(select_textobjects) do
                vim.keymap.set({ 'x', 'o' }, lhs, function()
                    require('nvim-treesitter-textobjects.select').select_textobject(capture, 'textobjects')
                end, { silent = true })
            end
        end,
    },

    -- Get highlight of nested functions
    {
        'atusy/tsnode-marker.nvim',
        dependencies = { 'nvim-treesitter/nvim-treesitter' },
        config = function()
            local function is_def(node)
                return vim.tbl_contains({
                    'func_literal',
                    'function_declaration',
                    'function_definition',
                    'method_declaration',
                    'method_definition',
                }, node:type())
            end

            vim.api.nvim_create_autocmd('FileType', {
                group = vim.api.nvim_create_augroup('tsnode-marker-markdown', {}),
                pattern = 'markdown',
                callback = function(ctx)
                    require('tsnode-marker').set_automark(ctx.buf, {
                        target = { 'code_fence_content' }, -- list of target node types
                        hl_group = 'TabLineFill', -- highlight group
                    })
                end,
            })
            vim.api.nvim_create_autocmd('FileType', {
                group = vim.api.nvim_create_augroup('tsnode-marker-nested-def', {}),
                pattern = { 'lua', 'python', 'go' }, -- whatever languages you want
                callback = function(ctx)
                    require('tsnode-marker').set_automark(ctx.buf, {
                        hl_group = 'TabLineFill', -- highlight group
                        target = function(_, node)
                            -- do not mark if the node does not satisfy is_def()
                            if not is_def(node) then
                                return false
                            end

                            -- mark if there is an ancestor node which satisfies is_def()
                            local parent = node:parent()
                            while parent do
                                if is_def(parent) then
                                    return true
                                end
                                parent = parent:parent()
                            end
                            return false
                        end,
                    })
                end,
            })
        end,
    },
}
