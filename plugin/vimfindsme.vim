" Vim global plugin for browsing files in your &path
" Maintainer:   Barry Arthur <barry.arthur@gmail.com>
" Version:      0.5
" Description:  "fuzzy" file finder, arglist manager, option editor and more
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
let g:vfm_version = '0.5'

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

if !exists('g:vfm_use_system_find')
  let g:vfm_use_system_find = 0
endif

" Private Functions: {{{1

function! s:SID()
  return "<SNR>" . matchstr(expand('<sfile>'), '<SNR>\zs\d\+_\zeSID$')
endfun

" Public Interface: {{{1
function! VimFindsMe(path)
  echom "Warning: The function name 'VimFindsMe' is deprecated. Use 'VimFindsMeFiles' instead."
  return VimFindsMeFiles(a:path)
endfunction

function! VimFindsMeFiles(path) "{{{2
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

  if (cwd == fnamemodify($HOME, ':p:h'))
        \ && (g:vfm_skip_home == 1)
        \ || ((index(paths, '.') != -1) && (g:vfm_maxdepth == -1))
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

  if g:vfm_use_system_find
    call vfm#show_list_overlay(vfm#uniq(sort(split(system(find_cmd), "\n"))))
  else
    let dotted = filter(vfm#globpath(join(paths, ','), '**/.*', 0, 1), 'v:val !~ "\\.\\.\\?$"')
    let files  = vfm#uniq(sort(dotted + vfm#globpath(join(paths, ','), '**/*', 0, 1)))
    call vfm#show_list_overlay(files)
  endif
  call vfm#overlay_controller({'<enter>' : ':exe "edit " . fnameescape(vfm#select_line())'})

endfunction "}}}2

function! s:vfm_dirs_callback()
  exe ':cd ' . vfm#select_line()
  echo getcwd()
endfunction

function! VimFindsMeDirs()
  call vfm#show_list_overlay(vfm#readfile(g:vfm_dirs_file))
  call vfm#overlay_controller({'<enter>' : ':call ' . s:SID() . 'vfm_dirs_callback()'})
endfunction

function! s:vfm_opts_callback(opt)
  let val = join(map(vfm#select_buffer()
        \ , 'substitute(v:val, "\\\\\\@<!,", "\\\\&", "g")')
        \ , ',')
  exe 'let &' . a:opt . ' =  "' . escape(val, '\\"') . '"'
endfunction

function! VimFindsMeOpts(opt)
  let opt = '&' . substitute(a:opt, '^&', '', '')
  if ! exists(opt)
    throw 'Unknown option ' . opt
  endif
  call vfm#show_list_overlay(split(eval(opt), '\\\@<!,'))
  call vfm#overlay_controller({
        \ '<enter>' : ':call ' . s:SID() . 'vfm_opts_callback("' . opt[1:] . '")'})
endfunction

function! s:vfm_args_callback()
  let arg = line('.')
  exe ':args ' . join(vfm#select_buffer(), ' ')
  exe 'argument ' . arg
endfunction

function! VimFindsMeArgs()
  let auto_act = g:vfm_auto_act_on_single_filter_result
  let g:vfm_auto_act_on_single_filter_result = 0
  call vfm#show_list_overlay(argv())
  let g:vfm_auto_act_on_single_filter_result = auto_act
  call vfm#overlay_controller(
        \ {
        \  '<enter>' : ':call ' . s:SID() . 'vfm_args_callback()'
        \ })
endfunction

function! VFMArgument(arg)
  let arg = a:arg
  if (type(arg) == type(0)) || (arg =~ '^\d\+$')
    exe 'argument ' . arg
  elseif type(arg) == type('')
    let bufname = bufname(arg)
    if bufname == ''
      echohl Warning
      echom "No unique buffer found with given partial."
      echohl None
    elseif index(argv(), bufname) == -1
      echohl Warning
      echom "Buffer " . bufnr(bufname) . " (" . bufname . ") is not in argument list."
      echohl None
    else
      exe 'argedit ' . fnameescape(bufname)
    endif
  else
    throw "Unexpected argument type: " . type(arg)
  endif
endfunction

function! VFMArglistComplete(ArgLead, CmdLine, CursorPos)
  return join(map(argv(), 'substitute(v:val, "^\\./", "", "")'), "\n")
endfunction

" Commands: {{{1
command! -nargs=0 -bar          VFMEdit     call VimFindsMeFiles(&path)
command! -nargs=0 -bar          VFMCD       call VimFindsMeDirs()
command! -nargs=1 -bar          VFMOpts     call VimFindsMeOpts(<q-args>)
command! -nargs=0 -bar          VFMArglist  call VimFindsMeArgs()
command! -nargs=0 -bar -range=% VFMArgs
      \ exe 'args ' . join(getline(<line1>,<line2>), ' ')
command! -nargs=0 -bar -range=% VFMArgadd
      \ exe 'argadd ' . join(getline(<line1>,<line2>), ' ')
command! -nargs=1 -bar -complete=custom,VFMArglistComplete
      \ VFMArgument call VFMArgument(<q-args>)

" Maps: {{{1
nnoremap <silent> <plug>vfm_browse_files  :VFMEdit<CR>
nnoremap <silent> <plug>vfm_browse_dirs   :VFMCD<CR>
nnoremap <silent> <plug>vfm_browse_paths  :call VimFindsMeOpts('&path')<CR>
nnoremap <silent> <plug>vfm_browse_args   :VFMArglist<CR>
nnoremap <silent> <plug>vfm_argument      :call feedkeys(":VFMArgument \<c-d>")<cr>

if !hasmapto('<plug>vfm_browse_files')
  nmap <unique><silent> <leader>ge <plug>vfm_browse_files
endif

if !hasmapto('<plug>vfm_browse_dirs')
  nmap <unique><silent> <leader>gd <plug>vfm_browse_dirs
endif

if !hasmapto('<plug>vfm_browse_paths')
  nmap <unique><silent> <leader>gp <plug>vfm_browse_paths
endif

if !hasmapto('<plug>vfm_browse_args')
  nmap <unique><silent> <leader>ga <plug>vfm_browse_args
endif

if !hasmapto('<plug>vfm_argument')
  nmap <unique><silent> <leader>gg <plug>vfm_argument
endif

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
