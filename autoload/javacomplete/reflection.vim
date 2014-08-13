let s:save_cpo= &cpo
set cpo&vim

let s:V= vital#of('javacomplete')
let s:P= s:V.import('Process')
let s:M= s:V.import('Vim.Message')
unlet s:V

let s:cache= {}  " FQN -> member list, e.g. {'java.lang.StringBuffer': classinfo, 'java.util': packageinfo, '/dir/TopLevelClass.java': compilationUnit}

let s:reflection= {
\   'attrs': {
\       'jvm': 'java',
\       'is_jdk11': 0,
\       'classpath': [],
\   },
\}

function! s:reflection.jvm(...)
    let self.attrs.jvm= get(a:, 0, self.attrs.jvm)

    if a:0 > 0
        let s:cache= {}
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

    let s:cache = {}
endfunction

function! s:reflection.remove_classpath(path)
    let paths= (type(a:path) == type([])) ? a:path : [a:path]

    for path in paths
        let idx= index(self.attrs.paths, path)

        if idx != -1
            call remove(self.attrs.paths, idx)
        endif
    endfor

    let s:cache= {}
endfunction

function! s:reflection.set_classpath(path)
    if type(a:path) == type([])
        let paths= deepcopy(a:path)
    else
        let paths= split(a:path, javacomplete#GetClassPathSep())
    endif

    let self.attrs.classpath= paths

    let s:cache = {}
endfunction

function! s:reflection.use_jdk11()
    let self.attrs.is_jdk11= 1
endfunction

function! s:reflection.packages()
    if !exists('s:all_packages_in_jars_loaded')
        " {'package name': {'tag': 'PACKAGE', 'classes': ['simple class name', ...]}}
        let packages= eval(self.run_reflection('-P', '-'))
        call extend(s:cache, packages)
        let s:all_packages_in_jars_loaded = 1
    endif

    return filter(keys(s:cache), 's:cache[v:val].tag ==# "PACKAGE"')
    " s:DoGetInfoByReflection('-', '-P')
endfunction

function! s:reflection.package_info(package)
    if !exists('s:all_packages_in_jars_loaded')
        " {'package name': {'tag': 'PACKAGE', 'classes': ['simple class name', ...]}}
        let packages= eval(self.run_reflection('-P', '-'))
        call extend(s:cache, packages)
        let s:all_packages_in_jars_loaded = 1
    endif

    return deepcopy(get(s:cache, a:package, {}))
endfunction

function! s:reflection.classes()
    return filter(keys(s:cache), 's:cache[v:val].tag ==# "CLASSDEF"')
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
  if has_key(s:cache, a:class)
    return s:cache[a:class]
  endif

  let res= self.run_reflection('-E', a:class)
  if res =~ '^[{\[]'
    let v= eval(res)
    if type(v) == type([])
      let s:cache[a:class]= sort(v)
    elseif type(v) == type({})
      if get(v, 'tag', '') =~# '^\(PACKAGE\|CLASSDEF\)$'
        let s:cache[a:class]= v
      else
        call extend(s:cache, v, 'force')
      endif
    endif
    unlet v
  else
    throw printf('javacomplete: %s', res)
  endif

  return get(s:cache, a:class, {})
endfunction

function! s:reflection.run_reflection(option, args)
  let classpath= ''

  if !self.attrs.is_jdk11
    let classpath= ' -classpath "' . javacomplete#util#convert_to_java_path(javacomplete#util#get_classpath()) . '" '
  endif

  let cmd= self.attrs.jvm . classpath . ' Reflection ' . a:option . ' "' . a:args . '"'
  return s:P.system(cmd)
endfunction

function! javacomplete#reflection#new()
    return deepcopy(s:reflection)
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
