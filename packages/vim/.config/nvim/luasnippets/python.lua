-- Python snippets, ported from UltiSnips/python.snippets.
-- Bodies carry their own relative indent as spaces (python ftplugin is
-- expandtab/sw=4); LuaSnip adds the indent of the expansion point on top.
local ls = require('luasnip')
local s, t, i, d, sn = ls.snippet, ls.text_node, ls.insert_node,
    ls.dynamic_node, ls.snippet_node
local rep = require('luasnip.extras').rep

-- UltiSnips' ${N:$M}: a tabstop you can edit, pre-filled with whatever is at
-- tabstop M. rep() is wrong here because it produces a frozen copy; only a
-- dynamicNode gives the copy-then-edit behaviour.
local function label_of(idx, ref)
    return d(idx, function(args) return sn(nil, { i(1, args[1]) }) end, { ref })
end

return {
    s({ trig = 'future' }, t({
        'from __future__ import (',
        '    absolute_import, division, print_function, unicode_literals)',
    })),

    s({ trig = 'utf8' }, t({ '# -*- coding: utf-8 -*-', '' })),

    s({ trig = 'class' }, {
        t('class '), i(1, 'SomeClass'), t('('), i(3, 'object'), t({ '):', '    def __init__(self, ' }),
        i(2, '*args, **kwargs'), t({ '):', '        super(' }), rep(1), t(', self).__init__('), rep(2), t(')'),
    }),

    -- was python 2 (`print >>sys.stderr`) and had a typo, '{$2:$1}' for
    -- '${2:$1}', which cost it the copy-then-edit label its siblings have
    s({ trig = 'err' }, {
        t("print('"), label_of(2, 1), t(" = ' + repr("), i(1, 'locals()'),
        t('), file=sys.stderr)  # noqa TODO'),
    }),

    s({ trig = 'lxml' }, {
        t({ 'from lxml.html import tostring', "print('========== <" }), label_of(2, 1),
        t([[> ==========\n%s\n========== </]]), rep(2), t([[> =========' % tostring(]]),
        i(1, 'locals()'), t('))  # noqa'),
    }),

    s({ trig = 'log' }, {
        t({ "with open('/tmp/q', 'a') as _f:  # TODO", "    _f.write('" }), label_of(2, 1),
        t([[ = %r\n' % (]]), i(1, 'locals()'), t(', ))  # noqa'),
    }),

    s({ trig = 'logd' }, {
        t({ "with open('/tmp/q', 'a') as _f:  # TODO", "    _f.write('" }), label_of(2, 1),
        t([[ = {\n')]]), t({ '', '    for _ in ' }), i(1, 'locals()'), t({ '.items():',
        [[        _f.write('  '+repr(_[0])+': '+repr(_[1])+',\n')]],
        [[    _f.write('}\n')]] }),
    }),

    -- the original emitted `try:` immediately followed by `except:`, a
    -- SyntaxError; the body is a tabstop now so it is valid and overwritable
    s({ trig = 'loge' }, {
        t({ 'try:', '    ' }), i(1, 'pass'), t({ '', 'except:',
        "    with open('/tmp/q', 'a') as _f:  # TODO",
        '        import sys',
        '        import traceback',
        '        _f.write("".join(traceback.format_exception(*sys.exc_info())))',
        '' }),
    }),

    s({ trig = 'jq' }, {
        t("with open('/tmp/"), i(2, 'q'), t({ "', 'a') as _f:  # TODO: remove the debug",
        '    import json', '    json.dump(' }), i(1, 'locals()'), t(', _f)  # TODO: remove this debug'),
    }),

    s({ trig = 'dir' }, {
        t('__expr = '), i(1, 'locals()'), t({ '  # TODO: remove this debug', "print('" }),
        label_of(2, 1), t({ " = %s:' % type(__expr))",
        'for _ in dir(__expr):',
        '    if not hasattr(__expr, _):',
        "        print('  .%s = <not set>' % _)",
        '    elif callable(getattr(__expr, _)):',
        "        print('  .%s()' % _)",
        '    else:',
        "        print('  .%s = %r' % (_, getattr(__expr, _)))",
        "print('}')",
        'del __expr  # TODO: remove this debug' }),
    }),

    s({ trig = 'logdir' }, {
        t({ "with open('/tmp/q', 'a') as _f:  # TODO", '    __expr = ' }), i(1, 'locals()'),
        t({ '  # TODO: remove this debug', "    _f.write('" }), label_of(2, 1),
        t([[ = %s:\n' % type(__expr))]]), t({ '',
        '    for _ in dir(__expr):',
        '        if not hasattr(__expr, _):',
        [[            _f.write('  .%s = <not set>\n' % _)]],
        '        elif callable(getattr(__expr, _)):',
        [[            _f.write('  .%s()\n' % _)]],
        '        else:',
        [[            _f.write('  .%s = %r\n' % (_, getattr(__expr, _)))]],
        [[    _f.write('}\n')]],
        '    del __expr  # TODO: remove this debug' }),
    }),

    s({ trig = 'q' }, {
        t({ 'import q  # TODO: REMOVE DEBUG', 'q(' }), i(1, 'locals()'), t(')'),
    }),

    s({ trig = 'qfake' }, {
        t("print('"), label_of(2, 1), t([[ (simulated!):\n%s\n' % str(]]), i(1, 'query'),
        t('.statement.compile('), i(3, 'dialect=sqlalchemy.dialects.dialect, '),
        t('compile_kwargs={"literal_binds": True})))  # noqa TODO'),
    }),

    s({ trig = 'qreal' }, {
        t("print('"), label_of(2, 1), t([[ (compiled):\n%s\n' % str(]]), i(1, 'query'),
        t('.statement))  # noqa TODO'),
    }),

    s({ trig = 'qlog' }, {
        t('__query = '), i(1, 'str(query.statement)'), t({ '', "with open('" }), i(2, '/tmp/q'),
        t({ "', 'a') as fp:  # TODO: remove this debug",
        [[    fp.write('\n')]],
        "    fp.write('=' * 79)",
        [[    fp.write('\n')]],
        [[    for __phrase in ['GROUP BY', 'WHERE', 'FROM', 'HAVING', 'ORDER BY', '(INNER\s+|OUTER\s+|LEFT\s+)*JOIN']:  # noqa]],
        [[        __query = __query.replace(' '+__phrase, '\n'+__phrase)]],
        [[    __query = __query.replace(', ', ',\n   ')]],
        "    #__query = __query % tuple(['VALUE1', 'VALUE2'])",
        '    fp.write(__query)',
        '    del __query' }),
    }),

    s({ trig = 'notimpl', desc = 'no implementation debug' }, {
        t("raise NotImplementedError('TODO :"), i(1, 'remove this'), t("') # noqa"),
    }),

    s({ trig = '#!' }, { t('#! /usr/bin/env python'), i(1, '2') }),

    s({ trig = 'main' }, {
        t({ 'if __name__ == "__main__":', '    ' }), i(1, 'main'), t('('), i(2), t(')'),
    }),

    s({ trig = 'pdb' }, t({ 'import pdb', 'pdb.set_trace()' })),

    s({ trig = 'ptpy' }, t({
        'from ptpython.repl import embed, run_config  # noqa: E501 TODO: REMOVE DEBUG',
        "embed(globals(), locals(), lambda repl: run_config(repl, '~/.config/ptpython/config.py'))  # noqa: E501 TODO: REMOVE DEBUG",
    })),

    s({ trig = 'verbose_sqlalchemy_requests' }, {
        t({ 'from lipy.rage import verbose_sqlalchemy_requests  # TODO: REMOVE DEBUG',
        '', 'with verbose_sqlalchemy_requests(' }), i(1, "'/tmp/q'"),
        t({ ') as sqllogger:', '    ' }), i(2, 'query.all()'),
    }),
}
