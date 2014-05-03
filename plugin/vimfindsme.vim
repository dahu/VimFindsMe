" Vim global plugin for browsing files in your &path
" Maintainer:	Barry Arthur <barry.arthur@gmail.com>
" Version:	0.2
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
      \ || v:version < 703
      \ || &compatible
  let &cpo = s:save_cpo
  echohl Warning
  echom "VimFindsMe depends on Vim 7.4 or later"
  echohl None
  finish
endif
let g:loaded_vimfindsme = 1

let g:vfm_version = '0.2'

" Options: {{{1
if !exists('g:vfm_skip_home')
  let g:vfm_skip_home = 1
endif

if !exists('g:vfm_maxdepth')
  let g:vfm_maxdepth = 4
endif

if !exists('g:vfm_hide_dirs')
  let g:vfm_hide_dirs = 1
endif

if !exists('g:vfm_ignore')
  let g:vfm_ignore = ['.hg', '.svn', '.bzr', '.git', 'CVS', '*.sw?']
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
    silent! buffer #
  endif
endfunction

function! s:select_file()
  let fname=getline('.')
  call s:close_overlay()
  exe "edit " . fnameescape(fname)
endfunction

function! s:uniq(list)
  if exists('*uniq')
    return uniq(a:list)
  endif
  let mlist = copy(a:list)
  let idx = len(a:list) - 1
  while idx >= 1
    if index(mlist, mlist[idx]) < idx
      call remove(a:list, idx)
    endif
    let idx -= 1
  endwhile
  return a:list
endfunction

" Public Interface: {{{1
function! VimFindsMe(path)
  let paths = filter(split(a:path, '\\\@<!,'), 'v:val !~ "^\s*;\s*$"')
  let cwd = getcwd()

  if index(paths, '.') != -1
    call add(paths, fnamemodify(expand('%'), ":p:h"))
  endif

  if (index(paths, '') != -1) || (index(paths, '**') != -1)
    call add(paths, cwd)
  endif

  call map(s:uniq(sort(filter(paths, 'index(["", ".", "**"], v:val) == -1')))
        \, 'substitute(v:val, "^" . cwd, ".", "")')

  if empty(paths)
    echohl Warning
    echom "VFM has nothing to do: paths empty."
    echohl None
    return
  endif

  if (cwd == fnamemodify('$HOME', ':p:h')) && (index(paths, '.') != -1)
        \ && (g:vfm_maxdepth == -1) && (g:vfm_skip_home != 0)
    echohl Warning
    echom "VFM skipping $HOME"
    echohl None
    return
  endif

  let find_prune = ' '
        \. join(map(copy(g:vfm_ignore),
        \    ' "-name " . fnameescape(v:val) . " -prune "'), ' -o ')
        \. '-o ' . (g:vfm_hide_dirs ? ' -type f ' : '') . ' -print'

  let find_depth = (g:vfm_maxdepth == -1 ? '' : ' -maxdepth ' . g:vfm_maxdepth)

  let find_cmd ="find -L " . join(paths, " ") . find_depth . find_prune

  call s:file_list_overlay(s:uniq(sort(split(system(find_cmd), "\n"))))
  nnoremap <buffer> q :call <SID>close_overlay()<cr>
  nnoremap <buffer> cv :v//d<cr>
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
