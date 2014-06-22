function! vfm#globpath(path, pattern, nosuf, aslist)
  if v:version == 704 && has('patch279')
    return globpath(a:path, a:pattern, a:nosuf, a:aslist)
  else
    return split(globpath(a:path, a:pattern, a:nosuf), "\n")
  endif
endfunction

function! vfm#uniq(list)
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

function! vfm#readfile(file)
  return filereadable(a:file) ? readfile(a:file) : []
endfunction

function! vfm#store_directory()
  if g:vfm_store_dirs
    let dirs = vfm#readfile(g:vfm_dirs_file)
    call add(dirs, fnamemodify(expand('%'), ":p:h"))
    call writefile(vfm#uniq(sort(dirs)), g:vfm_dirs_file)
  endif
endfunction

function! vfm#overlay_controller(...)
  nnoremap <buffer> q :call vfm#close_overlay()<cr>
  nnoremap <buffer> cv :v//d<cr>
  if a:0
    for [key, act] in items(a:1)
      exe 'nnoremap <buffer> ' . key . ' ' . act . '<cr>'
    endfor
  endif
endfunction

function! vfm#show_list_overlay(files)
  let s:altbuf = bufnr('#')

  if g:vfm_use_split
    hide noautocmd split
  endif
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
  if exists(':Filter')
    Filter
  else
    call feedkeys('/')
  endif
  if g:vfm_auto_act_on_single_filter_result
    if line('$') == 1
      call feedkeys("\<enter>")
    endif
  endif
endfunction

function! vfm#close_overlay()
  if g:vfm_use_split
    let scratch_buf = bufnr('')
    wincmd q
    exe 'bwipe ' . scratch_buf
  else
    buffer #
    bwipe #
    if buflisted(s:altbuf)
      exe 'buffer ' . s:altbuf
      silent! buffer #
    endif
  endif
endfunction

function! vfm#select_line()
  let fname = getline('.')
  call vfm#close_overlay()
  return fname
endfunction

function! vfm#select_buffer()
  let lines = getline(1,'$')
  call vfm#close_overlay()
  return lines
endfunction
