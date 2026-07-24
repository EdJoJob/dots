vim.opt_local.softtabstop = 3
vim.opt_local.shiftwidth = 3
vim.opt_local.tabstop = 3
vim.opt_local.spell = true
vim.api.nvim_buf_create_user_command(0, 'Preview', function()
    vim.fn.jobstart({
        'restview',
        '--css=/Users/eevans43/src/rhythm.css/dist/css/rhythm.css',
        '--css=/Users/eevans43/src/rhythm.css/syntax/molokai.css',
        vim.fn.expand('%:p'),
    })
end, {})
