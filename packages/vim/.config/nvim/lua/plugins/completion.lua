-- Completion: nvim-cmp fed by LSP, LuaSnip, buffer and path sources.
return {
    -- Snippets
    {
        'L3MON4D3/LuaSnip',
        config = function()
            local ls = require('luasnip')
            -- Personal snippets live in stdpath('config')/luasnippets, one lua
            -- file per filetype; lazy_load only reads a file when its filetype
            -- is first opened
            require('luasnip.loaders.from_lua').lazy_load({
                paths = vim.fn.stdpath('config') .. '/luasnippets',
            })

            vim.keymap.set('i', '<M-Space>', function()
                ls.expand()
            end, { silent = true, desc = 'expand snippet' })
            -- jump backward; LuaSnip keymaps are global where UltiSnips' were
            -- buffer-local while a snippet was active, so gate on
            -- locally_jumpable to keep <c-k> free otherwise
            vim.keymap.set({ 'i', 's' }, '<c-k>', function()
                if ls.locally_jumpable(-1) then
                    ls.jump(-1)
                end
            end, { silent = true, desc = 'previous snippet tabstop' })
        end,
    },

    {
        'hrsh7th/nvim-cmp',
        dependencies = {
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-path',
            'saadparwaiz1/cmp_luasnip',
            'L3MON4D3/LuaSnip',
        },
        config = function()
            vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }

            local cmp = require('cmp')
            local ls = require('luasnip')

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
                        ls.lsp_expand(args.body)
                    end,
                },
                mapping = {
                    -- TAB: confirm completion / expand or jump snippet /
                    -- literal tab after whitespace / trigger completion
                    ['<Tab>'] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.confirm({ select = true })
                        elseif ls.expandable() then
                            ls.expand()
                        elseif ls.locally_jumpable(1) then
                            ls.jump(1)
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
                    -- old coc maps.
                    ['<C-f>'] = cmp.mapping(function()
                        if cmp.visible_docs() then
                            cmp.scroll_docs(4)
                        else
                            vim.api.nvim_feedkeys(t('<Right>'), 'n', false)
                        end
                    end, { 'i' }),
                    -- <C-b> is snippet jump-forward while a snippet is active,
                    -- then docs-scroll, then <Left>.  Under UltiSnips the jump
                    -- took precedence via a buffer-local map; LuaSnip's maps
                    -- are global, so the precedence is spelled out here.
                    ['<C-b>'] = cmp.mapping(function()
                        if ls.locally_jumpable(1) then
                            ls.jump(1)
                        elseif cmp.visible_docs() then
                            cmp.scroll_docs(-4)
                        else
                            vim.api.nvim_feedkeys(t('<Left>'), 'n', false)
                        end
                    end, { 'i', 's' }),
                },
                sources = cmp.config.sources({
                    { name = 'nvim_lsp' },
                    { name = 'luasnip' },
                }, {
                    { name = 'buffer' },
                    { name = 'path' },
                }),
            })
        end,
    },
}
