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

function! vfm#select_line()
  let fname = getline('.')
  call overlay#close_overlay()
  return fname
endfunction

function! vfm#select_buffer()
  let lines = getline(1,'$')
  call overlay#close_overlay()
  return lines
endfunction
