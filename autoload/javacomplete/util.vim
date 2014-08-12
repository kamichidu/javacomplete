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

function! javacomplete#util#get_classpath()
    let path= s:GetJavaCompleteClassPath() . javacomplete#GetClassPathSep()

    if &ft == 'jsp'
        let path.= s:GetClassPathOfJsp()
    endif

    if exists('b:classpath') && b:classpath !~ '^\s*$'
        return path . b:classpath
    endif

    if exists('s:classpath')
        return path . javacomplete#GetClassPath()
    endif

    if exists('g:java_classpath') && g:java_classpath !~ '^\s*$'
        return path . g:java_classpath
    endif

    return path . $CLASSPATH
endfunction

function! s:GetClassPathOfJsp()
    if exists('b:classpath_jsp')
        return b:classpath_jsp
    endif

    let b:classpath_jsp= ''
    let path= expand('%:p:h')
    while 1
        if isdirectory(path . '/WEB-INF' )
            if isdirectory(path . '/WEB-INF/classes')
                let b:classpath_jsp.= s:PATH_SEP . path . '/WEB-INF/classes'
            endif
            if isdirectory(path . '/WEB-INF/lib')
                let libs= globpath(path . '/WEB-INF/lib', '*.jar')
                if libs != ''
                    let b:classpath_jsp.= s:PATH_SEP . substitute(libs, "\n", s:PATH_SEP, 'g')
                endif
            endif
            return b:classpath_jsp
        endif

        let prev= path
        let path= fnamemodify(path, ":p:h:h")
        if path == prev
            break
        endif
    endwhile
    return ''
endfunction

function! s:GetJavaCompleteClassPath()
    " remove *.class from wildignore if it exists, so that globpath doesn't ignore Reflection.class
    " vim versions >= 702 can add the 1 flag to globpath which ignores '*.class" in wildingore
    let has_class= 0
    if &wildignore =~# "*.class"
        set wildignore-=*.class
        let has_class= 1
    endif

    let classfile= globpath(&rtp, 'autoload/Reflection.class')
    if classfile == ''
        " try to find source file and compile to $HOME
        let srcfile= globpath(&rtp, 'autoload/Reflection.java')
        let srcfile= javacomplete#util#convert_to_java_path(srcfile)
        let classdir= javacomplete#util#convert_to_java_path(fnamemodify(srcfile, ':h'))

        if srcfile != ''
            let result= s:P.system(javacomplete#GetCompiler() . ' -d ' . shellescape(classdir) . ' ' . shellescape(srcfile))
            let classfile= globpath(&rtp, 'autoload/Reflection.class')
            if classfile == ''
                call s:M.error(srcfile . ' can not be compiled. Please check it')
            endif
        else
            call s:M.error('No Reflection.class found in $HOME/.vim or any autoload directory of the &rtp. And no Reflection.java found in any autoload directory of the &rtp to compile.')
        endif
    endif

    " add *.class to wildignore if it existed before
    if has_class == 1
        set wildignore+=*.class
    endif

    return fnamemodify(classfile, ':p:h')
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
