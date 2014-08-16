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

    it 'gets all class names'
        let classes= filter(g:R.classes(), 'v:val =~# "^jp\\."')
        Expect classes ==# [
        \   'jp.michikusa.chitose.unitejavaimport.DatabaseRepository',
        \   'jp.michikusa.chitose.unitejavaimport.InMemoryRepository',
        \   'jp.michikusa.chitose.unitejavaimport.Repository',
        \   'jp.michikusa.chitose.unitejavaimport.predicate.IsConstructor',
        \   'jp.michikusa.chitose.unitejavaimport.predicate.IsInitializer',
        \   'jp.michikusa.chitose.unitejavaimport.predicate.IsPublic',
        \   'jp.michikusa.chitose.unitejavaimport.predicate.IsStatic',
        \   'jp.michikusa.chitose.unitejavaimport.predicate.IsStaticInitializer',
        \   'jp.michikusa.chitose.unitejavaimport.predicate.RegexMatch',
        \   'jp.michikusa.chitose.unitejavaimport.predicate.StartsWithPackage',
        \   'jp.michikusa.chitose.unitejavaimport.util.AbstractTaskWorker',
        \   'jp.michikusa.chitose.unitejavaimport.util.AggregateWorkerSupport',
        \   'jp.michikusa.chitose.unitejavaimport.util.GenericOption',
        \   'jp.michikusa.chitose.unitejavaimport.util.KeepAliveOutputStream',
        \   'jp.michikusa.chitose.unitejavaimport.util.Pair',
        \   'jp.michikusa.chitose.unitejavaimport.util.TaskWorker',
        \   'jp.michikusa.chitose.unitejavaimport.util.WorkerSupport',
        \]
    end
end
