" For version 5.x: Clear all syntax items
" For version 6.x: Quit when a syntax file was already loaded
if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

" Keywords
syn keyword ogslLabel		define map reference
syn keyword ogslFunction	required one_of optional deprecated
syn keyword ogslTypeSpecifier	string bool int list blob

"integer number, or floating point number without a dot.
syn match  ogslNumber		"\<\d\+\>"
"floating point number, with dot
syn match  ogslNumber		"\<\d\+\.\d*\>"
"floating point number, starting with a dot
syn match  ogslNumber		"\.\d\+\>"

" String and Character contstants
syn region  ogslString		start=+"+  skip=+\\\\\|\\"+  end=+"+

syn region  ogslComment		start="//" skip="\\$" end="$"
syn region  ogslComment		start="/\*" end="\*/"

syn region  ogslDefine		start="^\s*#" skip="\\$" end="$" keepend

" Define the default highlighting.
" For version 5.7 and earlier: only when not done already
" For version 5.8 and later: only when an item doesn't have highlighting yet
if version >= 508 || !exists("did_ogsl_syntax_inits")
  if version < 508
    let did_ogsl_syntax_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif

  HiLink ogslLabel		Label
  HiLink ogslConditional	Conditional
  HiLink ogslRepeat		Repeat
  HiLink ogslLineNumber		Comment
  HiLink ogslNumber		Number
  HiLink ogslError		Error
  HiLink ogslStatement		Statement
  HiLink ogslString		String
  HiLink ogslComment		Comment
  HiLink ogslDefine		Comment
  HiLink ogslSpecial		Special
  HiLink ogslTodo		Todo
  HiLink ogslFunction		Identifier
  HiLink ogslTypeSpecifier Type
  HiLink ogslFilenumber ogslTypeSpecifier

  delcommand HiLink
endif

let b:current_syntax = "ogsl"

" vim: ts=8
