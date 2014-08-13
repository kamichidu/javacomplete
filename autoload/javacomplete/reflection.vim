let s:save_cpo= &cpo
set cpo&vim

let s:V= vital#of('javacomplete')
let s:P= s:V.import('Process')
unlet s:V

let s:cache= {}  " FQN -> member list, e.g. {'java.lang.StringBuffer': classinfo, 'java.util': packageinfo, '/dir/TopLevelClass.java': compilationUnit}

let s:reflection= {
\   'is_jdk11': 0,
\}

function! s:reflection.packages()
    return eval(self.run_reflection('-P', '-'))
    " s:DoGetInfoByReflection('-', '-P')
endfunction

" classes is a comma separated class name
function! s:reflection.check_exists_and_read_class_info(classes)
    return eval(self.run_reflection('-E', a:classes))
    " s:DoGetInfoByReflection(a:fqn, '-E')
    " s:RunReflection('-E', commalist, 'DoGetTypeInfoForFQN in Batch')
    " s:RunReflection('-E', commalist, 's:SearchStaticImports in Batch')
endfunction

function! s:reflection.class_info(class)
    return eval(self.run_reflection('-C', a:class))
    " s:RunReflection('-C', a:fqn, 's:DoGetReflectionClassInfo')
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

  if !self.is_jdk11
    let classpath= ' -classpath "' . javacomplete#util#convert_to_java_path(javacomplete#util#get_classpath()) . '" '
  endif

  let cmd= javacomplete#GetJVMLauncher() . classpath . ' Reflection ' . a:option . ' "' . a:args . '"'
  return s:P.system(cmd)
endfunction

function! javacomplete#reflection#new()
    return deepcopy(s:reflection)
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
