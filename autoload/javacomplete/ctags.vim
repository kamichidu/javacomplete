let s:save_cpo= &cpo
set cpo&vim

let s:V= vital#of('javacomplete')
let s:P= s:V.import('Process')
unlet s:V

let s:ctags= {
\   'attrs': {
\       'ctags': 'ctags',
\   },
\}

function! s:ctags.find_types(opt)
    return self.run(a:opt.path, {
    \   'recurse': get(a:opt, 'recurse', 0),
    \   'kinds': ['c', 'g', 'i'],
    \})
endfunction

function! s:ctags.run(dir, extra)
    let recurse= get(a:extra, 'recurse', 0) ? 'yes' : 'no'

    let options= []
    let options+= ['-f', '-']
    let options+= ['--langmap=java:.java']
    let options+= ['--languages=java']
    let options+= ['--java-kinds=' . join(get(a:extra, 'kinds', []), '')]
    let options+= ['--recurse=' . recurse]

    if recurse ==# 'no'
        let options+= [a:dir . '/*']
    endif

    let save_cwd= getcwd()
    try
        execute 'lcd' a:dir

        let cmd= join([self.attrs.ctags] + options, ' ')
        let output= s:P.system(cmd)
        let records= map(split(output, '\%(\r\n\|\r\|\n\)'), 'split(v:val, "\t", 1)')

        let tags= []
        for fields in records
            let [tagname, tagfile, tagaddress, tagkind]= fields[0 : 3]

            let package= tagfile
            let package= substitute(package, '\c\.java$', '', '')
            let package= substitute(package, '\%(/\|\\\)\+', '.', 'g')
            let package= substitute(package, '^\.\+', '', '')
            let package= substitute(package, '\C\.' . tagname . '$', '', '')

            let modifiers= {
            \   'is_public':    match(tagaddress, '\C\<public\>') != -1,
            \   'is_protected': match(tagaddress, '\C\<protected\>') != -1,
            \   'is_private':   match(tagaddress, '\C\<private\>') != -1,
            \}

            let tags+= [{
            \   'class':     tagname,
            \   'package':   package,
            \   'modifiers': modifiers,
            \   'kind':      tagkind,
            \   'file':      fnamemodify(tagfile, ':p'),
            \}]
        endfor

        return tags
    finally
        execute 'lcd' save_cwd
    endtry
endfunction

function! javacomplete#ctags#new()
    return deepcopy(s:ctags)
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
