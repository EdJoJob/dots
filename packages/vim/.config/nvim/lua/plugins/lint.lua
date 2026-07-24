-- ALE: linters (and the odd fixer) only -- completion/goto/hover come from
-- neovim's native LSP (see plugins/lsp.lua).
return {
    {
        'dense-analysis/ale',
        init = function()
            -- must be set before ALE loads
            vim.g.ale_disable_lsp = 1

            vim.g.ale_sign_column_always = 1
            vim.g.ale_echo_msg_error_str = 'E'
            vim.g.ale_echo_msg_warning_str = 'W'
            vim.g.ale_echo_msg_info_str = 'I'
            vim.g.ale_echo_msg_format = '[%linter%:%severity%%code%] %s'

            vim.g.ale_python_mypy_options = '--follow-imports=silent'
            vim.g.ale_markdown_vale_options = '--config .vale.ini'

            vim.g.ale_use_neovim_diagnostics_api = 1

            vim.g.ale_fixers = {
                typescript = { 'eslint' },
            }
            vim.g.ale_fix_on_save = 1
        end,
    },
}
