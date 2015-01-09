" Vim color file - fine_blue
" Generated by http://bytefluent.com/vivify 2014-04-01
set background=light
if version > 580
	hi clear
	if exists("syntax_on")
		syntax reset
	endif
endif

set t_Co=256
let g:colors_name = "fine_blue"

hi IncSearch guifg=#404054 guibg=#40ffff guisp=#40ffff gui=NONE ctermfg=240 ctermbg=87 cterm=NONE
hi WildMenu guifg=#f8f8f8 guibg=#00aacc guisp=#00aacc gui=NONE ctermfg=15 ctermbg=38 cterm=NONE
"hi SignColumn -- no settings --
hi SpecialComment guifg=#005858 guibg=#ccf7ee guisp=#ccf7ee gui=NONE ctermfg=23 ctermbg=195 cterm=NONE
hi Typedef guifg=#7040ff guibg=NONE guisp=NONE gui=NONE ctermfg=13 ctermbg=NONE cterm=NONE
hi Title guifg=#004060 guibg=#c8f0f8 guisp=#c8f0f8 gui=NONE ctermfg=23 ctermbg=195 cterm=NONE
hi Folded guifg=#7820ff guibg=#e0d8ff guisp=#e0d8ff gui=NONE ctermfg=57 ctermbg=189 cterm=NONE
hi PreCondit guifg=#0070e6 guibg=NONE guisp=NONE gui=NONE ctermfg=26 ctermbg=NONE cterm=NONE
hi Include guifg=#0070e6 guibg=NONE guisp=NONE gui=NONE ctermfg=26 ctermbg=NONE cterm=NONE
"hi TabLineSel -- no settings --
hi StatusLineNC guifg=#b8b8c0 guibg=#404054 guisp=#404054 gui=NONE ctermfg=7 ctermbg=240 cterm=NONE
"hi CTagsMember -- no settings --
hi NonText guifg=#4000ff guibg=#ececf0 guisp=#ececf0 gui=NONE ctermfg=57 ctermbg=255 cterm=NONE
"hi CTagsGlobalConstant -- no settings --
hi DiffText guifg=#4040ff guibg=#c0c0ff guisp=#c0c0ff gui=NONE ctermfg=13 ctermbg=147 cterm=NONE
hi ErrorMsg guifg=#ff0070 guibg=#ffe0f4 guisp=#ffe0f4 gui=NONE ctermfg=197 ctermbg=225 cterm=NONE
hi Ignore guifg=#f8f8f8 guibg=NONE guisp=NONE gui=NONE ctermfg=15 ctermbg=NONE cterm=NONE
hi Debug guifg=#005858 guibg=#ccf7ee guisp=#ccf7ee gui=NONE ctermfg=23 ctermbg=195 cterm=NONE
"hi PMenuSbar -- no settings --
hi Identifier guifg=#c800ff guibg=NONE guisp=NONE gui=NONE ctermfg=165 ctermbg=NONE cterm=NONE
hi SpecialChar guifg=#005858 guibg=#ccf7ee guisp=#ccf7ee gui=NONE ctermfg=23 ctermbg=195 cterm=NONE
hi Conditional guifg=#7040ff guibg=NONE guisp=NONE gui=NONE ctermfg=13 ctermbg=NONE cterm=NONE
hi StorageClass guifg=#7040ff guibg=NONE guisp=NONE gui=NONE ctermfg=13 ctermbg=NONE cterm=NONE
hi Todo guifg=#ff0070 guibg=#ffe0f4 guisp=#ffe0f4 gui=NONE ctermfg=197 ctermbg=225 cterm=NONE
hi Special guifg=#005858 guibg=#ccf7ee guisp=#ccf7ee gui=NONE ctermfg=23 ctermbg=195 cterm=NONE
hi LineNr guifg=#a0a0b0 guibg=NONE guisp=NONE gui=NONE ctermfg=103 ctermbg=NONE cterm=NONE
hi StatusLine guifg=#f8f8f8 guibg=#404054 guisp=#404054 gui=NONE ctermfg=15 ctermbg=240 cterm=NONE
hi Normal guifg=#404048 guibg=#f8f8f8 guisp=#f8f8f8 gui=NONE ctermfg=238 ctermbg=15 cterm=NONE
hi Label guifg=#7040ff guibg=NONE guisp=NONE gui=NONE ctermfg=13 ctermbg=NONE cterm=NONE
"hi CTagsImport -- no settings --
hi PMenuSel guifg=#f8f8f8 guibg=#404054 guisp=#404054 gui=NONE ctermfg=15 ctermbg=240 cterm=NONE
hi Search guifg=#404054 guibg=#ffffa0 guisp=#ffffa0 gui=NONE ctermfg=240 ctermbg=229 cterm=NONE
"hi CTagsGlobalVariable -- no settings --
hi Delimiter guifg=#005858 guibg=#ccf7ee guisp=#ccf7ee gui=NONE ctermfg=23 ctermbg=195 cterm=NONE
hi Statement guifg=#008858 guibg=NONE guisp=NONE gui=NONE ctermfg=29 ctermbg=NONE cterm=NONE
"hi SpellRare -- no settings --
"hi EnumerationValue -- no settings --
hi Comment guifg=#ff00c0 guibg=NONE guisp=NONE gui=NONE ctermfg=199 ctermbg=NONE cterm=NONE
hi Character guifg=#2020ff guibg=#e8e8ff guisp=#e8e8ff gui=NONE ctermfg=21 ctermbg=189 cterm=NONE
"hi Float -- no settings --
hi Number guifg=#2020ff guibg=#e8e8ff guisp=#e8e8ff gui=NONE ctermfg=21 ctermbg=189 cterm=NONE
hi Boolean guifg=#008858 guibg=NONE guisp=NONE gui=NONE ctermfg=29 ctermbg=NONE cterm=NONE
hi Operator guifg=#7040ff guibg=NONE guisp=NONE gui=NONE ctermfg=13 ctermbg=NONE cterm=NONE
"hi CursorLine -- no settings --
"hi Union -- no settings --
"hi TabLineFill -- no settings --
hi Question guifg=#008050 guibg=NONE guisp=NONE gui=NONE ctermfg=6 ctermbg=NONE cterm=NONE
hi WarningMsg guifg=#ff0070 guibg=#ffe0f4 guisp=#ffe0f4 gui=NONE ctermfg=197 ctermbg=225 cterm=NONE
"hi VisualNOS -- no settings --
hi DiffDelete guifg=#4040ff guibg=#c8f2ea guisp=#c8f2ea gui=NONE ctermfg=13 ctermbg=195 cterm=NONE
hi ModeMsg guifg=#0070ff guibg=NONE guisp=NONE gui=NONE ctermfg=27 ctermbg=NONE cterm=NONE
"hi CursorColumn -- no settings --
hi Define guifg=#0070e6 guibg=NONE guisp=NONE gui=NONE ctermfg=26 ctermbg=NONE cterm=NONE
hi Function guifg=#c800ff guibg=NONE guisp=NONE gui=NONE ctermfg=165 ctermbg=NONE cterm=NONE
hi FoldColumn guifg=#aa60ff guibg=#f0f0f4 guisp=#f0f0f4 gui=NONE ctermfg=135 ctermbg=255 cterm=NONE
hi PreProc guifg=#0070e6 guibg=NONE guisp=NONE gui=NONE ctermfg=26 ctermbg=NONE cterm=NONE
"hi EnumerationName -- no settings --
hi Visual guifg=#404060 guibg=#dddde8 guisp=#dddde8 gui=NONE ctermfg=60 ctermbg=254 cterm=NONE
hi MoreMsg guifg=#a800ff guibg=NONE guisp=NONE gui=NONE ctermfg=129 ctermbg=NONE cterm=NONE
"hi SpellCap -- no settings --
hi VertSplit guifg=#f8f8f8 guibg=#404054 guisp=#404054 gui=NONE ctermfg=15 ctermbg=240 cterm=NONE
hi Exception guifg=#7040ff guibg=NONE guisp=NONE gui=NONE ctermfg=13 ctermbg=NONE cterm=NONE
hi Keyword guifg=#7040ff guibg=NONE guisp=NONE gui=NONE ctermfg=13 ctermbg=NONE cterm=NONE
hi Type guifg=#7040ff guibg=NONE guisp=NONE gui=NONE ctermfg=13 ctermbg=NONE cterm=NONE
hi DiffChange guifg=#5050ff guibg=#e0e0ff guisp=#e0e0ff gui=NONE ctermfg=63 ctermbg=189 cterm=NONE
hi Cursor guifg=#0000ff guibg=#00e0ff guisp=#00e0ff gui=NONE ctermfg=21 ctermbg=45 cterm=NONE
"hi SpellLocal -- no settings --
hi Error guifg=#ffffff guibg=#ff4080 guisp=#ff4080 gui=NONE ctermfg=15 ctermbg=13 cterm=NONE
hi PMenu guifg=#b8b8c0 guibg=#404054 guisp=#404054 gui=NONE ctermfg=7 ctermbg=240 cterm=NONE
hi SpecialKey guifg=#d87000 guibg=NONE guisp=NONE gui=NONE ctermfg=166 ctermbg=NONE cterm=NONE
hi Constant guifg=#2020ff guibg=#e8e8ff guisp=#e8e8ff gui=NONE ctermfg=21 ctermbg=189 cterm=NONE
"hi DefinedName -- no settings --
hi Tag guifg=#005858 guibg=#ccf7ee guisp=#ccf7ee gui=NONE ctermfg=23 ctermbg=195 cterm=NONE
hi String guifg=#2020ff guibg=#e8e8ff guisp=#e8e8ff gui=NONE ctermfg=21 ctermbg=189 cterm=NONE
hi PMenuThumb guifg=NONE guibg=#a0a0b0 guisp=#a0a0b0 gui=NONE ctermfg=NONE ctermbg=103 cterm=NONE
"hi MatchParen -- no settings --
"hi LocalVariable -- no settings --
hi Repeat guifg=#7040ff guibg=NONE guisp=NONE gui=NONE ctermfg=13 ctermbg=NONE cterm=NONE
"hi SpellBad -- no settings --
"hi CTagsClass -- no settings --
hi Directory guifg=#0070b8 guibg=NONE guisp=NONE gui=NONE ctermfg=25 ctermbg=NONE cterm=NONE
hi Structure guifg=#7040ff guibg=NONE guisp=NONE gui=NONE ctermfg=13 ctermbg=NONE cterm=NONE
hi Macro guifg=#0070e6 guibg=NONE guisp=NONE gui=NONE ctermfg=26 ctermbg=NONE cterm=NONE
hi Underlined guifg=#0000ff guibg=NONE guisp=NONE gui=NONE ctermfg=21 ctermbg=NONE cterm=NONE
hi DiffAdd guifg=#4040ff guibg=#c8f2ea guisp=#c8f2ea gui=NONE ctermfg=13 ctermbg=195 cterm=NONE
"hi TabLine -- no settings --
hi cursorim guifg=#f8f8f8 guibg=#8000ff guisp=#8000ff gui=NONE ctermfg=15 ctermbg=93 cterm=NONE
"hi clear -- no settings --
hi titled guifg=#000000 guibg=#fffdfa guisp=#fffdfa gui=NONE ctermfg=NONE ctermbg=230 cterm=NONE
hi lcursor guifg=#f8f8f8 guibg=#8000ff guisp=#8000ff gui=NONE ctermfg=15 ctermbg=93 cterm=NONE
hi htmlitalic guifg=NONE guibg=NONE guisp=NONE gui=italic ctermfg=NONE ctermbg=NONE cterm=NONE
hi htmlboldunderlineitalic guifg=NONE guibg=NONE guisp=NONE gui=bold,italic,underline ctermfg=NONE ctermbg=NONE cterm=bold,underline
hi djangostatement guifg=#005f00 guibg=#ddffaa guisp=#ddffaa gui=NONE ctermfg=22 ctermbg=193 cterm=NONE
hi htmlbolditalic guifg=NONE guibg=NONE guisp=NONE gui=bold,italic ctermfg=NONE ctermbg=NONE cterm=bold
hi doctrans guifg=#ffffff guibg=#ffffff guisp=#ffffff gui=NONE ctermfg=15 ctermbg=15 cterm=NONE
hi helpnote guifg=#000000 guibg=#ffd700 guisp=#ffd700 gui=NONE ctermfg=NONE ctermbg=220 cterm=NONE
hi htmlunderlineitalic guifg=NONE guibg=NONE guisp=NONE gui=italic,underline ctermfg=NONE ctermbg=NONE cterm=underline
hi doccode guifg=#00aa00 guibg=NONE guisp=NONE gui=NONE ctermfg=34 ctermbg=NONE cterm=NONE
hi docspecial guifg=#4876ff guibg=NONE guisp=NONE gui=NONE ctermfg=69 ctermbg=NONE cterm=NONE
hi htmlbold guifg=NONE guibg=NONE guisp=NONE gui=bold ctermfg=NONE ctermbg=NONE cterm=bold
hi htmlboldunderline guifg=NONE guibg=NONE guisp=NONE gui=bold,underline ctermfg=NONE ctermbg=NONE cterm=bold,underline
hi htmlunderline guifg=NONE guibg=NONE guisp=NONE gui=underline ctermfg=NONE ctermbg=NONE cterm=underline
hi htmlstatement guifg=#af5f87 guibg=NONE guisp=NONE gui=NONE ctermfg=132 ctermbg=NONE cterm=NONE