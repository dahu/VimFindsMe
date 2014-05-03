" Vim global plugin for browsing files in your &path
" Maintainer:	Barry Arthur <barry.arthur@gmail.com>
" Version:	0.1
" Description:	"fuzzy" file finder using mostly vim internals
"		and the system find comand.
" Last Change:	2014-05-03
" License:	Vim License (see :help license)
" Location:	plugin/vimfindsme.vim
" Website:	https://github.com/dahu/vimfindsme
"
" See vimfindsme.txt for help.  This can be accessed by doing:
"
" :helptags ~/.vim/doc
" :help vimfindsme

" Vimscript Setup: {{{1
" Allow use of line continuation.
let s:save_cpo = &cpo
set cpo&vim

if exists("g:loaded_vimfindsme")
      \ || v:version < 704
      \ || &compatible
  let &cpo = s:save_cpo
  echohl Warning
  echom "VimFindsMe depends on Vim 7.4 or later"
  echohl None
  finish
endif
let g:loaded_vimfindsme = 1

" Options: {{{1
if !exists('g:vfm_ignore_extensions')
  let g:vfm_ignore_extensions = ['\.sw.*']
endif

" Private Functions: {{{1
function! s:file_list_overlay(files)
  let s:altbuf = bufnr('#')

  hide noautocmd enew
  setlocal buftype=nofile
  setlocal bufhidden=hide
  setlocal noswapfile
  let old_is = &incsearch
  set incsearch
  let old_hls = &hlsearch
  set hlsearch
  call append(0, a:files)
  $
  delete _
  redraw
  1
  call feedkeys('/')
endfunction

function! s:close_overlay()
  buffer #
  bwipe #
  if buflisted(s:altbuf)
    exe 'buffer ' . s:altbuf
    buffer #
  endif
endfunction

function! s:select_file()
  let fname=getline('.')
  call s:close_overlay()
  exe "edit " . fnameescape(fname)
endfunction

" Public Interface: {{{1
function! VimFindsMe(path)
  let paths = filter(split(a:path, '\\\@<!,'), 'v:val !~ "^\\(\\*\\*\\|;\\)$"')
  let cwd = getcwd()
  if index(paths, '.') != -1
    call add(paths, fnamemodify(expand('%'), ":p:h"))
  endif
  if index(paths, '') != -1
    call add(paths, cwd)
  endif

  call map(uniq(filter(paths, 'index(["", "."], v:val) == -1'))
        \, 'substitute(v:val, "^" . cwd, "./", "")')
  let find_prune = ' -regextype posix-extended -regex "(.*/\.git.*)|(.*('
        \. join(g:vfm_ignore_extensions, '|')
        \. ')$)" -prune -o -print'
  let find_cmd ="find " . join(paths, " ") . find_prune

  call s:file_list_overlay(uniq(sort(split(system(find_cmd), "\n"))))
  nnoremap <buffer> q :call <SID>close_overlay()<cr>
  nnoremap <buffer> <enter> :call <SID>select_file()<cr>
endfunction

" Maps: {{{1
nnoremap <Plug>vfm_browse :call VimFindsMe(&path)<CR>

if !hasmapto('<Plug>vfm_browse')
  nmap <unique><silent> <leader><tab> <Plug>vfm_browse
endif

" Commands: {{{1
command! -nargs=0 -bar VFM call VimFindsMe(&path)

" Teardown:{{{1
"reset &cpo back to users setting
let &cpo = s:save_cpo

" Template From: https://github.com/dahu/Area-41/
" vim: set sw=2 sts=2 et fdm=marker:
