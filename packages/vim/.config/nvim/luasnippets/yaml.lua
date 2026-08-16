-- Ansible debug snippets, ported from UltiSnips/yaml.snippets.
-- Indents are 2 spaces to match the yaml ftplugin (expandtab/sw=2), which is
-- what UltiSnips produced from the tabs in the original.
local ls = require('luasnip')
local s, t, i = ls.snippet, ls.text_node, ls.insert_node
local rep = require('luasnip.extras').rep

return {
    -- NOTE: module/content/dest sit at the same indent as local_action rather
    -- than under it, carried over verbatim from the original. Almost certainly
    -- not the Ansible task this means to describe, but fixing it is a guess at
    -- intent, so it is left as-is.
    s({ trig = 'debug-local' }, {
        t({ '- name: Debug host info',
        '  local_action:',
        '  module: copy',
        '  content: "{{ ' }), i(1, 'hostvars'),
        t({ ' | to_nice_json }}"',
        '  dest: ~/tmp/ansible/' }), rep(1), t('-'), i(2, 'play'),
        t('-{{ inventory_hostname }}.json'),
    }),

    s({ trig = 'debug-all' }, t({
        '- name: Debug Local All Vars',
        '  local_action:',
        '  module: copy',
        '  src: {{ msg }}',
        '  dest: ~/tmp/ansible/all',
        '  vars:',
        '    msg: |',
        '      Module Variables ("vars"):',
        '      --------------------------------',
        '      {{ vars | to_nice_json }}',
        '',
        '      Environment Variables ("environment"):',
        '      --------------------------------',
        '      {{ environment | to_nice_json }}',
        '',
        '      GROUP NAMES Variables ("group_names"):',
        '      --------------------------------',
        '      {{ group_names | to_nice_json }}',
        '',
        '      GROUPS Variables ("groups"):',
        '      --------------------------------',
        '      {{ groups | to_nice_json }}',
        '',
        '      HOST Variables ("hostvars"):',
        '      --------------------------------',
        '      {{ hostvars | to_nice_json }}',
    })),
}
