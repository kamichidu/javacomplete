let s:save_cpo= &cpo
set cpo&vim

let s:V= vital#of('javacomplete')
let s:P= s:V.import('Process')
let s:S= s:V.import('Data.String')
let s:L= s:V.import('Data.List')
let s:M= s:V.import('Vim.Message')
let s:FP= s:V.import('System.Filepath')
unlet s:V

" Convert a path into the form that java expects on this platform
" Really only needed for running windows java from cygwin
function! javacomplete#util#convert_to_java_path(path)
    if has('win32unix')
        if ! exists('s:windows_java_under_unix')
            let s:windows_java_under_unix= match(s:P.system("which " . shellescape(javacomplete#GetJVMLauncher())), "^/cygdrive") >= 0
        endif
        if s:windows_java_under_unix
            return substitute(s:P.system("cygpath --windows " . shellescape(a:path)), "\n", "", "")
        endif
    else
        return a:path
    endif
endfunction

" => [1|0, 'path/to/file']
function! javacomplete#util#typename2filename(typename, srcpaths)
    " top-level type
    " java.util.Map.Entry => 'java/util/Map/Entry.java'
    let relpaths= []
    let relpaths+= [s:S.replace(a:typename, '.', '/') . '.java']
    " nested type
    " 'java.util.Map.Entry' => ['java/util/Map.java', 'java/util.java', 'java.java']
    let idents= split(a:typename, '\.')
    call s:L.pop(idents)
    while !empty(idents)
        let relpaths+= [join(idents, '/') . '.java']
        call s:L.pop(idents)
    endwhile

    for relpath in relpaths
        let filename= globpath(join(a:srcpaths, ','), relpath)
        if !empty(filename)
            return {
            \   'found': 1,
            \   'filename': s:FP.unify_separator(filename),
            \}
        endif
    endfor

    return {'found': 0}
endfunction

" => {'found': 1|0, 'dirname': 'path/to/dir', 'idents': ['rest', 'identifier']}
function! javacomplete#util#typename2dirname(typename, srcpaths)
    return {'found': 0}
    for path in a:srcpaths
      let idents = split(a:typename, '\.')
      let i = len(idents)-2
      while i >= 0
        let dirpath = path . '/' . join(idents[:i], '/')
        " it is a package
        if isdirectory(dirpath)
          let dirs[s:FP.unify_separator(fnamemodify(dirpath, ':p:h'))]= {'fqn': fqn, 'idents': idents[i + 1 : ]}
          break
        endif
        let i -= 1
      endwhile
    endfor
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
