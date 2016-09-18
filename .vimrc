syntax on
set nonu
set cursorline
set ruler
set ignorecase smartcase
set nowrapscan
set incsearch
set hlsearch
set noerrorbells
"set smartindent
"set smarttab
"set sw=4
"set ts=4
"set expandtab
"set tabstop=8 softtabstop=8 shiftwidth=8 noexpandtab
"autocmd BufWrite * :%s/\s*$//ge

"set tags=/home/yadong/jb_ww45b/linux/kernel/drivers/usb/tags
set cscopequickfix=s-,c-,d-,i-,t-,e-

filetype on

let Tlist_Show_One_File=1
let Tlist_Exit_OnlyWindow=1

"cs add cscope.out
"if filereadable("cscope.out")
"	cs add cscope.out
"elseif
"	cs add $CSCOPE_DB
"endif

	if has("cscope")
		set cscopetag cscopeverbose
		"set csprg=/usr/local/bin/cscope
		set csto=0
		set cst
		set nocsverb
		" add any database in current directory
		"if filereadable("cscope.out")
		"    cs add cscope.out
		" else add database pointed to by environment
		"elseif $CSCOPE_DB != ""
		"    cs add $CSCOPE_DB
		"endif
		set csverb
	endif


nmap <C-\>s :cs find s <C-R>=expand("<cword>")<CR><CR>
nmap <C-\>g :cs find g <C-R>=expand("<cword>")<CR><CR>
nmap <C-\>c :cs find c <C-R>=expand("<cword>")<CR><CR>
nmap <C-\>t :cs find t <C-R>=expand("<cword>")<CR><CR>
nmap <C-\>e :cs find e <C-R>=expand("<cword>")<CR><CR>
nmap <C-\>f :cs find f <C-R>=expand("<cfile>")<CR><CR>
nmap <C-\>i :cs find i ^<C-R>=expand("<cfile>")<CR>$<CR>
nmap <C-\>d :cs find d <C-R>=expand("<cword>")<CR><CR>
