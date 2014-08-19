let R= javacomplete#reflection#new()

let start_time= reltime()
let packages= R.packages()
echo '1st packages - ' . reltimestr(reltime(start_time)) . ' [s]'
" echo packages

let start_time= reltime()
let packages= R.packages()
echo '2nd packages - ' . reltimestr(reltime(start_time)) . ' [s]'
" echo packages

let start_time= reltime()
let classes= R.classes()
echo '1st classes - ' . reltimestr(reltime(start_time)) . ' [s]'
" echo classes

let start_time= reltime()
let classes= R.classes()
echo '2nd classes - ' . reltimestr(reltime(start_time)) . ' [s]'
" echo classes

let start_time= reltime()
let class= R.class_info('java.util.concurrent.ConcurrentSkipListSet')
echo '1st class info - ' . reltimestr(reltime(start_time)) . ' [s]'
" echo classes

let start_time= reltime()
let class= R.class_info('java.util.concurrent.ConcurrentSkipListSet')
echo '2nd class info - ' . reltimestr(reltime(start_time)) . ' [s]'
" echo classes
