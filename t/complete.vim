describe 'javacomplete#Complete'
    before
        new
        setfiletype java
    end

    after
        close!
    end

    it 'can get complete position'
        read t/fixtures/Simple.java

        call cursor(7, 12)
        let pos= javacomplete#Complete(1, '')

        Expect pos == 11

        call cursor(8, 15)
        let pos= javacomplete#Complete(1, '')

        Expect pos == 11

        call cursor(9, 10)
        let pos= javacomplete#Complete(1, '')

        Expect pos == -1
    end

    it 'test'
        read t/fixtures/Simple.java

        Expect javacomplete#do_get_type_info_for_fqn(['java.lang.Object'], 't/fixtures/') ==# []
    end

    " it 'can gather candidates'
    "     read t/fixtures/Simple.java
    "
    "     call cursor(16, 11)
    "     let pos= javacomplete#Complete(1, '')
    "
    "     Expect b:javacomplete_context.precending ==# 'o.'
    "     Expect b:javacomplete_context.incomplete ==# ''
    "     Expect b:javacomplete_context.context_type ==# 'after dot'
    "     Expect pos == 10
    "
    "     call feedkeys("\<C-X>\<C-O>", 'n')
    "     let candidates= javacomplete#Complete(0, '')
    "
    "     Expect candidates ==# [
    "     \   {'abbr': 'equals()',    'dup': '1', 'kind': 'm', 'menu': 'boolean equals(Object)', 'word': 'equals('},
    "     \   {'abbr': 'getClass()',  'dup': '1', 'kind': 'm', 'menu': 'Class getClass()',       'word': 'getClass('},
    "     \   {'abbr': 'hashCode()',  'dup': '1', 'kind': 'm', 'menu': 'int hashCode()',         'word': 'hashCode('},
    "     \   {'abbr': 'notify()',    'dup': '1', 'kind': 'm', 'menu': 'void notify()',          'word': 'notify('},
    "     \   {'abbr': 'notifyAll()', 'dup': '1', 'kind': 'm', 'menu': 'void notifyAll()',       'word': 'notifyAll('},
    "     \   {'abbr': 'toString()',  'dup': '1', 'kind': 'm', 'menu': 'String toString()',      'word': 'toString('},
    "     \   {'abbr': 'wait()',      'dup': '1', 'kind': 'm', 'menu': 'void wait(long, int)',   'word': 'wait('},
    "     \   {'abbr': 'wait()',      'dup': '1', 'kind': 'm', 'menu': 'void wait(long)',        'word': 'wait('},
    "     \   {'abbr': 'wait()',      'dup': '1', 'kind': 'm', 'menu': 'void wait()',            'word': 'wait('},
    "     \]
    " end
end
