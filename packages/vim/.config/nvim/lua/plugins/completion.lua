-- Completion: nvim-cmp fed by LSP, UltiSnips, buffer and path sources.
return {
    -- Snippets
    {
        'SirVer/ultisnips',
        init = function()
            vim.g.UltiSnipsExpandTrigger = '<M-Space>'
            vim.g.UltiSnipsJumpForwardTrigger = '<c-b>'
            vim.g.UltiSnipsJumpBackwardTrigger = '<c-k>'
            vim.g.UltiSnipsEditSplit = 'context'
            -- Personal snippets live in stdpath('config')/UltiSnips, which
            -- UltiSnips finds by scanning &runtimepath for dirs of this name
            vim.g.UltiSnipsSnippetDirectories = { 'UltiSnips' }
        end,
    },

    {
        'hrsh7th/nvim-cmp',
        dependencies = {
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-path',
            'quangnguyen30192/cmp-nvim-ultisnips',
            'SirVer/ultisnips',
        },
        config = function()
            vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }

            local cmp = require('cmp')
            require('cmp_nvim_ultisnips').setup({})

            local function has_space_before()
                local col = vim.fn.col('.') - 1
                return col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') ~= nil
            end
            local t = function(keys)
                return vim.api.nvim_replace_termcodes(keys, true, false, true)
            end

            cmp.setup({
                snippet = {
                    expand = function(args)
                        vim.fn['UltiSnips#Anon'](args.body)
                    end,
                },
                mapping = {
                    -- TAB: confirm completion / expand or jump snippet /
                    -- literal tab after whitespace / trigger completion
                    ['<Tab>'] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.confirm({ select = true })
                        elseif vim.fn['UltiSnips#CanExpandSnippet']() == 1 then
                            vim.fn['UltiSnips#ExpandSnippet']()
                        elseif vim.fn['UltiSnips#CanJumpForwards']() == 1 then
                            vim.fn['UltiSnips#JumpForwards']()
                        elseif has_space_before() then
                            fallback()
                        else
                            cmp.complete()
                        end
                    end, { 'i', 's' }),
                    ['<C-e>'] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.abort()
                        else
                            fallback()
                        end
                    end, { 'i' }),
                    ['<C-Space>'] = cmp.mapping.complete(),
                    -- Scroll the docs float; arrow-key fallback mirrors the
                    -- old coc maps.  UltiSnips' jump-forward <C-b> is
                    -- buffer-local while a snippet is active and keeps
                    -- precedence over these, as it did under coc.
                    ['<C-f>'] = cmp.mapping(function()
                        if cmp.visible_docs() then
                            cmp.scroll_docs(4)
                        else
                            vim.api.nvim_feedkeys(t('<Right>'), 'n', false)
                        end
                    end, { 'i' }),
                    ['<C-b>'] = cmp.mapping(function()
                        if cmp.visible_docs() then
                            cmp.scroll_docs(-4)
                        else
                            vim.api.nvim_feedkeys(t('<Left>'), 'n', false)
                        end
                    end, { 'i' }),
                },
                sources = cmp.config.sources({
                    { name = 'nvim_lsp' },
                    { name = 'ultisnips' },
                }, {
                    { name = 'buffer' },
                    { name = 'path' },
                }),
            })
        end,
    },
}
