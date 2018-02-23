" Matt Day's .vimrc
" Latest version always here: https://github.com/mattsday/dotfiles/

"================
"    General
"================
" I'm lazy and launch vim with 'vi' - when I do this I don't want to emulate
" vi and all the nastiness that it comes with
set nocompatible

"================
"    Keybind
"================
" Disable the shift+q shortcut (Q) that enters Ex mode by default
" I always fat-finger this by accident... :(
:map Q <Nop>

"================
"  Spelling
"================
" To spell check a document, you will need to enter :set spell, this just 
" defaults to British English (my preference)
if has("spell")
	set spelllang=en_gb
endif

"================
"  Look & Feel
"================
" Syntax hilighting (if enabled and not running vim.tiny)
if has("syntax")
	syntax on
endif
" Show me where in the file I am at all times (col/line)
set ruler
" I always have a black-background in my terminals, tell vim this
set background=dark
" If using the VimR app, set the background to black
if has("gui_vimr")
	highlight Normal guibg=Black
endif
" Disable the mouse (enabled by default in neovim)
set mouse-=a
" Enable auto indenting (maintain position between lines)
set autoindent
" Set tab width to 4
set tabstop=4
set shiftwidth=4
set softtabstop=4
" Hilight matching parenthesis etc
set showmatch
" Allow indentation based on file type if available
if has("autocmd")
	filetype plugin indent on
endif

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

" OS X Crontab stuff
autocmd filetype crontab setlocal nobackup nowritebackup

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

