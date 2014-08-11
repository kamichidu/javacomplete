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
end
