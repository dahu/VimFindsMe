function! vfm#globpath(path, pattern, nosuf, aslist)
  if v:version == 704 && has('patch279')
    return globpath(a:path, a:pattern, a:nosuf, a:aslist)
  else
    return split(globpath(a:path, a:pattern, a:nosuf), "\n")
  endif
endfunction

" Don't just rely on internal uniq() because it assumes a sorted list.
function! vfm#uniq(list)
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
