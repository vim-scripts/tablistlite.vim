" Tabtracker plugin v1.0
" Last Change:	2011 july
" Maintainer:	Sandeep.c.r<sandeepcr2@gmail.com>
"
"
" This plugin keeps track of the tabs you were working in recently, so that
" you may switch back to them easily.
" 
" Command to open the recently worked tab list is
"
" :Tablisttoggle
"
" To make this plugin really useful you have to assign a shortcut key for this, 
" say you want F2 key to open the tab list.
"
" you can add the following line in your .vimrc file. 
"
"             map <F2> :Tablisttoggle<CR>
"
" If you are on windows " the file name would be _vimrc. The .vimrc file is  
" usually present in the users home directory.
"
" vimrc file will be hidden in linux so you will have to do a ls -ah to see it. 
"
" If the file  is not present you can just add one file with this line only.
"
" you have to Restart vim 
"
" Invoking this plugin opens a new horizontal window above the currently window
"
" This window will contain a list of tabs(that are still open).
"
" The tabs are sorted on order in which you accessed. Top line shows the last tab
" you were on. The previous tab below it and so on.
"
" To switch to a tab in the list, double click on the line or press enter when
" you are on the corresponding line. 
"
" when a tab is closed, that tab is removed from the list.
"
" The tablist window closes automatically once you selected a tab, or when the
" tablist window loses focus.

function! s:get_tab_ls()
	let l:tabs = {}
	for l:i in range(tabpagenr('$'))
		let l:buf_list_for_this_tab = tabpagebuflist(l:i+1)
		for l:j in l:buf_list_for_this_tab 
			let l:bufname = bufname(l:j)
			if(strlen(l:bufname) > 0) 
				let l:tabs[l:j] = [l:i+1,l:bufname]
			endif
		endfor
	endfor
	return l:tabs
endfunction

function! s:open_new_window(dim)
	exe a:dim . 'new' 
	set nonu
	setlocal bt=nofile
	setlocal bt=nowrite
	setlocal bufhidden=delete
	setlocal noswapfile
	setlocal scrolloff=0
	setlocal sidescrolloff=0
	return bufnr('%')
endfunction 

function! s:search_for_buf(bufno,tlist)
	for l:i in range(len(a:tlist))
		if(a:tlist[l:i][0] == a:bufno) 
			return l:i
		endif
	endfor
	return 0;
endfunction
		
function! s:display_tab_list(tab_list)
	let b:lookup = {}
	let l:line = 1
	for l:i in s:tlstrecent
	if(exists("l:tabdetails")) 
		unlet l:tabdetails
	endif
		if(has_key(a:tab_list,l:i))
			let l:tabdetails = get(a:tab_list,l:i)
			"let l:parts = split(l:tabdetails[1],'[\/]')
			let l:short_file_name = pathshorten(l:tabdetails[1])
			call setline(l:line,l:short_file_name)
			let b:lookup[l:short_file_name] = l:tabdetails[0]
			let l:line += 1
		endif
	endfor
endfunction

function! s:refresh()
	let s:tablist = s:get_tab_ls()
	call s:display_tab_list(s:tablist)
endfunction

function! s:close()
	if(exists("t:tlistbuf"))
		unlet t:tlistbuf
		augroup  Tlistaco1
			autocmd!
		augroup END
		:q!
	endif
endfunction


function! s:toggle()
	if(exists("t:tlistbuf"))
		call s:close()
		return 0
	endif
	let s:tablist = s:get_tab_ls()
	let t:tlistbuf = s:open_new_window(20)
	call s:display_tab_list(s:tablist)
	call matchadd('Keyword','[\/\\][^\/\\]*$')  
	setlocal nomodifiable
	map <buffer> <silent> <2-leftrelease> :call <sid>gototab()<cr>
	map <buffer> <silent> <C-R> :call <sid>gototab()<cr>
	map <buffer> <silent> <C-M> :call <sid>gototab()<cr>
	map <buffer> <silent> r :call <sid>refresh()<cr>
	augroup  Tlistaco1
			autocmd!
			au  BufLeave <buffer> call <sid>close()
	augroup END
endfunction

function! s:gototab()
	let l:llindex= getline('.')
	let l:tabno = b:lookup[l:llindex]
	"echo l:tabno
	call s:switch_tab(l:tabno)
endfunction


function! s:switch_tab(tabno)
	exe a:tabno. ' tabn'
endfunction


function! s:sort_list_using_index(lst,index)
	let l:ld = {}
	let l:rlst = []
	for l:i in a:lst
		let l:ld[l:i[a:index]] = l:i
	endfor
	for l:j in sort(keys(l:ld))
		call add(l:rlst,l:ld[l:j])
	endfor
	return l:rlst
endfunction

function! s:updaterecent()
	let l:thistab = tabpagenr()
	let l:buf_list_for_this_tab = tabpagebuflist(l:thistab)
	for l:j in l:buf_list_for_this_tab 
		let l:bufname = bufname(l:j)
		if(strlen(l:bufname) > 0 && getbufvar(l:j,'&modifiable')) 
			call filter(s:tlstrecent, 'v:val !='. l:j)
			call insert(s:tlstrecent,l:j)
			if(len(s:tlstrecent) > 30) 
				call remove(s:tlstrecent,30,-1)
			endif
		endif
	endfor
endfunction

let s:tlstrecent = []
let s:tablist = {}
augroup Tlistacom
		autocmd!
		au  TabLeave * call <sid>updaterecent()
augroup END

command! Tablisttoggle :call <sid>toggle()
