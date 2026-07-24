; extends

; functions and methods
(function_declaration body: (block) @fold)
(method_declaration body: (block) @fold)
(func_literal body: (block) @fold)

; control flow
(if_statement consequence: (block) @fold)
(if_statement alternative: (block) @fold)
(for_statement body: (block) @fold)

; switch and select
(expression_switch_statement) @fold
(type_switch_statement) @fold
(select_statement) @fold
(expression_case) @fold
(type_case) @fold
(default_case) @fold
(communication_case) @fold
