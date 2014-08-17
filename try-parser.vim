call java_parser#InitParser(readfile(expand('~/local/java/default/src/java/util/concurrent/ConcurrentSkipListSet.java')))
let start_time= reltime()
let unit= java_parser#compilationUnit()
echo reltimestr(reltime(start_time))

PP unit
