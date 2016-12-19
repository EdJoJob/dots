" use <SPACE>i to run the whole file through isort
nnoremap <buffer> <space>i :%!isort -<CR>
" if user leaves Insert mode on a line that looks like an import, run isort
"augroup IsortAutomatic
"au! InsertLeave <buffer> if getline('.') =~ '^\%(from\|import\)\s\+' | exe '%!isort -' | exe 'undojoin' | endif
"augroup end
