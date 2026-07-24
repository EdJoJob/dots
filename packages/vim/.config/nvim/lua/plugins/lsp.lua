-- Native LSP configuration.
--
-- Adding a language server
-- ------------------------
-- 1. Install the binary so it's on PATH (add it to install/Brewfile or
--    install/tools.sh / packages-*.txt so new machines get it too).
-- 2. If nvim-lspconfig ships a config for it (:help lspconfig-all), just
--    add its name to the vim.lsp.enable() table below.  If not, define a
--    config first:
--        vim.lsp.config('name', { cmd = {...}, filetypes = {...}, root_markers = {...} })
--    then enable it.
-- vim.lsp.enable() autostarts the server on matching FileType events; no
-- external process manager is involved -- nvim spawns and owns the child
-- process, keeps one instance per root directory, and the server exits
-- with nvim.
return {
    {
        'neovim/nvim-lspconfig',
        dependencies = { 'hrsh7th/cmp-nvim-lsp', 'ibhagwan/fzf-lua' },
        config = function()
            -- Remove nvim's default gr* LSP maps so the buffer-local gr/gi
            -- below fire without a timeoutlen disambiguation wait
            for _, lhs in ipairs({ 'grn', 'grr', 'gri', 'gra', 'grt' }) do
                pcall(vim.keymap.del, 'n', lhs)
            end
            pcall(vim.keymap.del, 'x', 'gra')

            -- Advertise nvim-cmp capabilities to every server
            vim.lsp.config('*', {
                capabilities = require('cmp_nvim_lsp').default_capabilities(),
            })

            vim.lsp.config('pyright', {
                settings = {
                    pyright = {
                        inlayHints = {
                            variableTypes = false,
                            functionReturnTypes = false,
                            parameterTypes = false,
                        },
                    },
                },
            })

            vim.lsp.config('yamlls', {
                settings = {
                    yaml = {
                        schemas = {
                            ['https://raw.githubusercontent.com/docker/cli/master/cli/compose/schema/data/config_schema_v3.9.json'] = '**/docker-compose*.ya?ml',
                            ['https://raw.githubusercontent.com/OAI/OpenAPI-Specification/master/schemas/v3.0/schema.json'] = '**/*.?openapi.yml',
                            ['https://dnwj8swjjbsbt.cloudfront.net/latest/gzip/CloudFormationResourceSpecification.json'] = '**/*.?cloudformation.ya?ml',
                        },
                    },
                },
            })

            -- Enable each server only when its binary is present; missing
            -- servers are silent no-ops
            local servers = {
                gopls = 'gopls',
                pyright = 'pyright-langserver',
                ts_ls = 'typescript-language-server',
                yamlls = 'yaml-language-server',
                jsonls = 'vscode-json-language-server',
                vimls = 'vim-language-server',
            }
            for server, binary in pairs(servers) do
                if vim.fn.executable(binary) == 1 then
                    vim.lsp.enable(server)
                end
            end

            -- Buffer-local mappings once a server attaches
            vim.api.nvim_create_autocmd('LspAttach', {
                group = vim.api.nvim_create_augroup('PERSONAL_LSP', { clear = true }),
                callback = function(ev)
                    local opts = { buffer = ev.buf, silent = true }
                    -- single result jumps, multiple results land in the quickfix list
                    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
                    vim.keymap.set('n', 'gy', vim.lsp.buf.type_definition, opts)
                    vim.keymap.set('n', 'gr', function() require('fzf-lua').lsp_references() end, opts)
                    vim.keymap.set('n', 'gi', function() require('fzf-lua').lsp_implementations() end, opts)
                    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
                    vim.keymap.set({ 'n', 'x' }, '<leader>a', vim.lsp.buf.code_action, opts)
                end,
            })

            -- Scroll the (hover) docs float with <C-f>/<C-b> without
            -- focusing it, normal behaviour when no float is open
            local function find_float()
                for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                    if vim.api.nvim_win_get_config(win).relative ~= '' then
                        return win
                    end
                end
                return nil
            end
            local t = function(keys)
                return vim.api.nvim_replace_termcodes(keys, true, false, true)
            end
            local function scroll_float_or_feed(keys)
                return function()
                    local win = find_float()
                    if win then
                        vim.api.nvim_win_call(win, function()
                            pcall(vim.cmd.normal, { t(keys), bang = true })
                        end)
                    else
                        vim.api.nvim_feedkeys(t(keys), 'n', false)
                    end
                end
            end
            vim.keymap.set({ 'n', 'x' }, '<C-f>', scroll_float_or_feed('<C-f>'), { silent = true })
            vim.keymap.set({ 'n', 'x' }, '<C-b>', scroll_float_or_feed('<C-b>'), { silent = true })

            -- Use K to show documentation in preview window: :help for
            -- vim/help files, LSP hover when a capable server is attached,
            -- 'keywordprg' otherwise
            local function show_documentation()
                if vim.tbl_contains({ 'vim', 'help' }, vim.bo.filetype) then
                    vim.cmd('h ' .. vim.fn.expand('<cword>'))
                elseif #vim.lsp.get_clients({ bufnr = 0, method = 'textDocument/hover' }) > 0 then
                    vim.lsp.buf.hover()
                else
                    vim.cmd('!' .. vim.o.keywordprg .. ' ' .. vim.fn.expand('<cword>'))
                end
            end
            vim.keymap.set('n', 'K', show_documentation, { silent = true })
        end,
    },
}
