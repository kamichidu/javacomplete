let s:save_cpo= &cpo
set cpo&vim

let s:V= vital#of('javacomplete')
let s:P= s:V.import('Process')
let s:M= s:V.import('Vim.Message')
let s:L= s:V.import('Data.List')
unlet s:V

let s:reflection= {
\   'attrs': {
\       'jvm': 'java',
\       'is_jdk11': 0,
\       'classpath': [],
\       'cache': {},
\       'packages_cached': 0,
\   },
\}

function! s:reflection.jvm(...)
    let self.attrs.jvm= get(a:, 0, self.attrs.jvm)

    if a:0 > 0
        call self.clear_cache()
    endif

    return self.attrs.jvm
endfunction

function! s:reflection.add_classpath(path)
    let paths= (type(a:path) == type([])) ? a:path : [a:path]

    for path in paths
        if !isdirectory(path) && !match(path, '\.jar$')
            call s:M.error('javacomplete: invalid classpath: ' . path)
            return
        endif
    endfor

    let self.attrs.classpath+= paths
    call self.clear_cache()
endfunction

function! s:reflection.remove_classpath(path)
    let paths= (type(a:path) == type([])) ? a:path : [a:path]

    for path in paths
        let idx= index(self.attrs.paths, path)

        if idx != -1
            call remove(self.attrs.paths, idx)
        endif
    endfor

    call self.clear_cache()
endfunction

function! s:reflection.set_classpath(path)
    if type(a:path) == type([])
        let paths= deepcopy(a:path)
    else
        let paths= split(a:path, javacomplete#GetClassPathSep())
    endif

    let self.attrs.classpath= paths
    call self.clear_cache()
endfunction

function! s:reflection.get_classpath()
    let paths= [s:get_javacomplete_classpath()]

    if &filetype ==# 'jsp'
        let paths+= s:GetClassPathOfJsp()
    endif
    if exists('b:classpath')
        let paths+= split(b:javacomplete_classpath, javacomplete#GetClassPathSep())
    elseif !empty(self.attrs.classpath)
        let paths+= self.attrs.classpath
    elseif exists('g:javacomplete_classpath')
        let paths+= split(g:javacomplete_classpath, javacomplete#GetClassPathSep())
    else
        let paths+= split($CLASSPATH, javacomplete#GetClassPathSep())
    endif

    return join(paths, javacomplete#GetClassPathSep())
endfunction

function! s:reflection.use_jdk11()
    let self.attrs.is_jdk11= 1
endfunction

function! s:reflection.packages()
    call self.ensure_cache()

    return sort(filter(keys(self.attrs.cache), 'self.attrs.cache[v:val].tag ==# "PACKAGE"'))
    " s:DoGetInfoByReflection('-', '-P')
endfunction

function! s:reflection.package_info(package)
    call self.ensure_cache()

    if !has_key(self.attrs.cache, a:package)
        return {}
    endif

    let package= deepcopy(self.attrs.cache[a:package])
    " ensure order
    let package.classes= sort(get(package, 'classes', []))
    let package.subpackages= sort(get(package, 'subpackages', []))
    return package
endfunction

function! s:reflection.classes()
    let packages= self.packages()
    let classes= []
    for package in packages
        let pkg_info= self.package_info(package)
        let classes+= map(get(pkg_info, 'classes', []), 'package . "." . v:val')
    endfor

    return sort(classes)
endfunction

" classes is a comma separated class name
function! s:reflection.check_exists_and_read_class_info(classes)
    return eval(self.run_reflection('-E', a:classes))
    " s:DoGetInfoByReflection(a:fqn, '-E')
    " s:RunReflection('-E', commalist, 'DoGetTypeInfoForFQN in Batch')
    " s:RunReflection('-E', commalist, 's:SearchStaticImports in Batch')
endfunction

function! s:reflection.class_info(class)
    let output= self.run_reflection('-C', a:class)
    try
        let expr= eval(output)
        return (type(expr) == type({})) ? expr : {}
    catch
        return {}
    endtry
    " s:RunReflection('-C', a:fqn, 's:DoGetReflectionClassInfo')
      " let ti = s:GetClassInfoFromSource(fqn[strridx(fqn, '.')+1:], files[fqn])
endfunction

function! s:reflection.package_or_class_info(class)
  if has_key(self.attrs.cache, a:class)
    return self.attrs.cache[a:class]
  endif

  let res= self.run_reflection('-E', a:class)
  if res =~ '^[{\[]'
    let v= eval(res)
    if type(v) == type([])
      let self.attrs.cache[a:class]= sort(v)
    elseif type(v) == type({})
      if get(v, 'tag', '') =~# '^\(PACKAGE\|CLASSDEF\)$'
        let self.attrs.cache[a:class]= v
      else
        call extend(self.attrs.cache, v, 'force')
      endif
    endif
    unlet v
  else
    throw printf('javacomplete: %s', res)
  endif

  return get(self.attrs.cache, a:class, {})
endfunction

function! s:reflection.run_reflection(option, args)
  let classpath= ''

  if !self.attrs.is_jdk11
    let classpath= ' -classpath "' . javacomplete#util#convert_to_java_path(self.get_classpath()) . '" '
  endif

  let cmd= self.attrs.jvm . classpath . ' Reflection ' . a:option . ' "' . a:args . '"'
  return s:P.system(cmd)
endfunction

function! s:reflection.ensure_cache()
    " check a cache already made
    if self.attrs.packages_cached
        return
    endif

    let packages= eval(self.run_reflection('-P', '-'))
    call extend(self.attrs.cache, packages)
    let self.attrs.packages_cached= 1
endfunction

function! s:reflection.clear_cache()
    let self.attrs.cache= {}
    let self.attrs.packages_cached= 0
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

function! s:get_javacomplete_classpath()
    " remove *.class from wildignore if it exists, so that globpath doesn't ignore Reflection.class
    " vim versions >= 702 can add the 1 flag to globpath which ignores '*.class" in wildingore
    if &wildignore =~# "*.class"
        set wildignore-=*.class
        let has_class= 1
    else
        let has_class= 0
    endif
    try
        let classfile= globpath(&rtp, 'autoload/Reflection.class')

        if empty(classfile)
            " try to find source file and compile to $HOME
            let srcfile= globpath(&rtp, 'autoload/Reflection.java')

            if !empty(srcfile)
                let srcfile= javacomplete#util#convert_to_java_path(srcfile)
                let classdir= javacomplete#util#convert_to_java_path(fnamemodify(srcfile, ':h'))

                let result= s:P.system(javacomplete#GetCompiler() . ' -d ' . shellescape(classdir) . ' ' . shellescape(srcfile))
                let classfile= globpath(&rtp, 'autoload/Reflection.class')
                if empty(classfile)
                    call s:M.error(srcfile . ' can not be compiled. Please check it')
                endif
            else
                call s:M.error('No Reflection.class found in $HOME/.vim or any autoload directory of the &rtp. And no Reflection.java found in any autoload directory of the &rtp to compile.')
            endif
        endif

        return fnamemodify(classfile, ':p:h')
    finally
        " add *.class to wildignore if it existed before
        if has_class == 1
            set wildignore+=*.class
        endif
    endtry
endfunction

function! javacomplete#reflection#new()
    return deepcopy(s:reflection)
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
