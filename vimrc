" Matt Day's .vimrc - http://matt.fragilegeek.com/vimrc
" Use at your own risk - these settings work for me...

"================
"  256 Colours!
"================
set t_Co=256

"================
"    General
"================
" I'm lazy and launch vim with 'vi' - when I do this I don't want to emulate
" vi and all the nastiness that it comes with
set nocompatible

"================
"  Spelling
"================
" To spell check a document, you will need to enter :set spell, this just defaults
" to British English (my preference)
set spelllang=en_GB

"================
"  Look & Feel
"================
" Syntax hilighting
syntax on
" Show me where in the file I am at all times (col/line)
set ruler
" I always have a black-background in my terminals, tell vim this
set background=dark
" If using the VimR app, set the background to black
if has("gui_vimr")
	highlight Normal guibg=Black
endif
" Auto-indent and be smart about it (note, type :set paste to paste text)
set autoindent
set smartindent
" Hilight matching parenthesis etc
set showmatch

"================
"    Editing
"================
" Improve backspace's usefulness:
set backspace=indent,eol,start
" Support OS X weirdness (\r) files (iTunes uses this amongst others)
set fileformats=unix,mac,dos
" Don't beep. Ever.
set noerrorbells
" Don't be fussy about case (e.g. searches)
set ignorecase

"================
" Numpad Hacks for Mac
"================
" Map numpad keys 0-9 to their respective digits
":imap <Esc>Oq 1
":imap <Esc>Or 2
":imap <Esc>Os 3
":imap <Esc>Ot 4
":imap <Esc>Ou 5
":imap <Esc>Ov 6
":imap <Esc>Ow 7
":imap <Esc>Ox 8
":imap <Esc>Oy 9
":imap <Esc>Op 0

" Map the mathematical ones too...
:imap <Esc>On .
:imap <Esc>OQ /
:imap <Esc>OR *
:imap <Esc>Ol +
:imap <Esc>OS -
:imap <Esc>Oo /
:imap <Esc>Oj *
:imap <Esc>OX =
:imap <Esc>Om -
:imap <Esc>Ok +

" Finally map the 'enter' key
:imap <Esc>OM <CR>

