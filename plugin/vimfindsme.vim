" Vim global plugin for browsing files in your &path
" Maintainer:   Barry Arthur <barry.arthur@gmail.com>
" Version:      0.3
" Description:  "fuzzy" file finder using mostly vim internals
"               and the system find comand.
" Last Change:  2014-05-08
" License:      Vim License (see :help license)
" Location:     plugin/vimfindsme.vim
" Website:      https://github.com/dahu/vimfindsme
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
  echom "VimFindsMe depends on Vim 7.3 or later"
  echohl None
  finish
endif

let g:loaded_vimfindsme = 1
let g:vfm_version = '0.3'

" Options: {{{1
if !exists('g:vfm_auto_act_on_single_filter_result')
  let g:vfm_auto_act_on_single_filter_result = 1
endif

if !exists('g:vfm_store_dirs')
  let g:vfm_store_dirs = 1
endif

if !exists('g:vfm_dirs_file')
  let g:vfm_dirs_file = expand('<sfile>:p:h:h') . '/user_dirs'
endif

if !exists('g:vfm_skip_home')
  let g:vfm_skip_home = 1
endif

if !exists('g:vfm_use_split')
  let g:vfm_use_split = 0
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

function s:SID()
  return "<SNR>" . matchstr(expand('<sfile>'), '<SNR>\zs\d\+_\zeSID$')
endfun

" Public Interface: {{{1
function! VimFindsMe(path)
  echom "Warning: The function name 'VimFindsMe' is deprecated. Use 'VimFindsMeFiles' instead."
  return VimFindsMeFiles(a:path)
endfunction

function! VimFindsMeFiles(path)
  let paths = filter(split(a:path, '\\\@<!,'), 'v:val !~ "^\s*;\s*$"')
  let cwd = getcwd()

  if index(paths, '.') != -1
    call add(paths, fnamemodify(expand('%'), ":p:h"))
  endif

  if (index(paths, '') != -1) || (index(paths, '**') != -1)
    call add(paths, cwd)
  endif

  call map(vfm#uniq(sort(filter(paths, 'index(["", ".", "**"], v:val) == -1')))
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

  call map(paths, 'fnameescape(v:val)')

  let find_prune = ' '
        \. join(map(copy(g:vfm_ignore),
        \    ' "-name " . fnameescape(v:val) . " -prune "'), ' -o ')
        \. '-o ' . (g:vfm_hide_dirs ? ' -type f ' : '') . ' -print'

  let find_depth = (g:vfm_maxdepth == -1 ? '' : ' -maxdepth ' . g:vfm_maxdepth)

  let find_cmd = "find -L " . join(paths, " ") . find_depth . find_prune
        \. ' 2>/dev/null'

  call vfm#file_list_overlay(vfm#uniq(sort(split(system(find_cmd), "\n"))))
  call vfm#overlay_controller({'<enter>' : ':exe "edit " . fnameescape(vfm#select_line())'})

endfunction

function! s:vfm_dirs_callback()
  exe ':cd ' . vfm#select_line()
  pwd
endfunction

function! VimFindsMeDirs()
  call vfm#file_list_overlay(vfm#readfile(g:vfm_dirs_file))
  call vfm#overlay_controller({'<enter>' : ':call ' . s:SID() . 'vfm_dirs_callback()'})
endfunction

function! s:vfm_paths_callback()
  exe 'set path=' . join(vfm#select_buffer(), ',')
endfunction

function! VimFindsMePaths()
  call vfm#file_list_overlay(map(split(&path, '\\\@<!,'), 'escape(v:val, "\\ ")'))
  call vfm#overlay_controller({'<enter>' : ':call ' . s:SID() . 'vfm_paths_callback()'})
endfunction

" Maps: {{{1
nnoremap <silent> <plug>vfm_browse_files  :call VimFindsMeFiles(&path)<CR>
nnoremap <silent> <plug>vfm_browse_dirs   :call VimFindsMeDirs()<CR>
nnoremap <silent> <plug>vfm_browse_paths  :call VimFindsMePaths()<CR>

if !hasmapto('<Plug>vfm_browse_files')
  nmap <unique><silent> <leader>ge <Plug>vfm_browse_files
endif

if !hasmapto('<Plug>vfm_browse_dirs')
  nmap <unique><silent> <leader>gd <Plug>vfm_browse_dirs
endif

if !hasmapto('<Plug>vfm_browse_paths')
  nmap <unique><silent> <leader>gp <Plug>vfm_browse_paths
endif

" Commands: {{{1
command! -nargs=0 -bar VFMFiles  call VimFindsMeFiles(&path)
command! -nargs=0 -bar VFMDirs   call VimFindsMeDirs()
command! -nargs=0 -bar VFMPaths  call VimFindsMePaths()

" Autocommands {{{1
" runtime autoload/vfm.vim
augroup VimFindsMe
  au!
  au BufRead * call vfm#store_directory()
augroup END

" Teardown:{{{1
"reset &cpo back to users setting
let &cpo = s:save_cpo

" Template From: https://github.com/dahu/Area-41/
" vim: set sw=2 sts=2 et fdm=marker:
