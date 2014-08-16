describe 'javacomplete#reflection'
    before
        let g:R= javacomplete#reflection#new()

        call g:R.add_classpath('./t/fixtures/test.jar')
    end

    it 'gets all package names'
        let packages= filter(g:R.packages(), 'v:val =~# "^jp\\."')
        Expect packages ==# [
        \   'jp.michikusa',
        \   'jp.michikusa.chitose',
        \   'jp.michikusa.chitose.unitejavaimport',
        \   'jp.michikusa.chitose.unitejavaimport.predicate',
        \   'jp.michikusa.chitose.unitejavaimport.util',
        \]
    end
end
