let s:save_cpo= &cpo
set cpo&vim

let s:V= vital#of('javacomplete')
let s:P= s:V.import('Process')
let s:M= s:V.import('Vim.Message')
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

let &cpo= s:save_cpo
unlet s:save_cpo
