-- Date/time snippets for every filetype.
-- Ported from UltiSnips/all.snippets: `!v strftime(...)` becomes
-- extras.partial(os.date, ...), lua's os.date being a strftime wrapper, so the
-- format strings carry over unchanged.
local ls = require('luasnip')
local s = ls.snippet
local partial = require('luasnip.extras').partial

-- The old `w` flag is LuaSnip's wordTrig default: it rejects a trigger only
-- when the preceding char is [%w_], so the '.' inside s.date is no obstacle.
return {
    s({ trig = 'today', desc = 'Human readable date' }, partial(os.date, '%d %b %Y')),
    s({ trig = 's.date', desc = 'sortable date' }, partial(os.date, '%Y-%m-%d')),
    s({ trig = 's.time', desc = 'sortable time' }, partial(os.date, '%H:%M')),
    s({ trig = 's.now', desc = 'Sortable date and time' }, partial(os.date, '%Y-%m-%d %H:%M')),
    s({ trig = 'now', desc = 'default date' }, partial(os.date, '%c')),
}
