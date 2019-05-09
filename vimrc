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

" Show me where in the file I am at all times (col/line)
set ruler

" Show line numbers
set number

" ...but make them grey
highlight LineNr term=bold cterm=NONE ctermfg=DarkGrey ctermbg=NONE gui=NONE guifg=DarkGrey guibg=NONE

" Highlight current line
set cursorline

" Show a tab-complete menu, e.g. when doing a :split
set wildmenu

" I always have a black-background in my terminals, tell vim this
set background=dark

" Syntax hilighting (if enabled and not running vim.tiny)
if has("syntax")
	syntax on
endif

if has("gui_vimr")
	" If using the VimR app, set the background to black
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

" Make tabs spaces
set expandtab

" Hilight matching parenthesis etc
set showmatch

" Allow indentation based on file type if available
filetype plugin indent on

if has("autocmd")
	" OS X Crontab stuff
	autocmd filetype crontab setlocal nobackup nowritebackup
	" YAML Files
	autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab
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

" Highlight search results
set hlsearch

" tmux support
if exists('$TMUX')
    let &t_SI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=1\x7\<Esc>\\"
    let &t_EI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=0\x7\<Esc>\\"
else
    let &t_SI = "\<Esc>]50;CursorShape=1\x7"
    let &t_EI = "\<Esc>]50;CursorShape=0\x7"
endif

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

