let s:save_cpo= &cpo
set cpo&vim

let s:cache= {}

let s:reflection= {}

function! s:reflection.packages()
    " s:DoGetInfoByReflection('-', '-P')
endfunction

" classes is a comma separated class name
function! s:reflection.check_exists_and_read_class_info(classes)
    return s:RunReflection(a:classes, '-E')
    " s:DoGetInfoByReflection(a:fqn, '-E')
    " s:RunReflection('-E', commalist, 'DoGetTypeInfoForFQN in Batch')
    " s:RunReflection('-E', commalist, 's:SearchStaticImports in Batch')
endfunction

function! s:reflection.class_info(class)
    return s:RunReflection('-C', a:class, 's:DoGetReflectionClassInfo')
    " s:RunReflection('-C', a:fqn, 's:DoGetReflectionClassInfo')
endfunction

function! s:DoGetInfoByReflection(class, option)
  if has_key(s:cache, a:class)
    return s:cache[a:class]
  endif

  let res = s:RunReflection(a:option, a:class, 's:DoGetInfoByReflection')
  if res =~ '^[{\[]'
    let v = eval(res)
    if type(v) == type([])
      let s:cache[a:class] = sort(v)
    elseif type(v) == type({})
      if get(v, 'tag', '') =~# '^\(PACKAGE\|CLASSDEF\)$'
        let s:cache[a:class] = v
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

function! s:RunReflection(option, args, log)
  let classpath = ''
  if !exists('s:isjdk11')
    let classpath = ' -classpath "' . s:ConvertToJavaPath(s:GetClassPath()) . '" '
  endif

  let cmd = javacomplete#GetJVMLauncher() . classpath . ' Reflection ' . a:option . ' "' . a:args . '"'
  return s:P.system(cmd)
endfunction

function! javacomplete#reflection#new()
    return deepcopy(s:reflection)
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
