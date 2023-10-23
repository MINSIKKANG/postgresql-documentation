package require Pgtcl
# getDBs :
# #   get the names of all the databases at a given host and port number
# #   with the defaults being the localhost and port 5432
# #   return them in alphabetical order

 proc connectDB { {host "127.0.0.1"} {port "5432"} {db "postgres"} {user "postgres"} {password "1234"} } {
     set conn [pg_connect $db -host $host -port $port -user $user -password $password]
     set conninfo [pg_dbinfo status $conn]
     puts $conninfo
     return $conn
 }

 proc getDBs { conn query } {
     # datnames is the list to be result
     set res [pg_exec $conn "$query"]
     set ntups [pg_result $res -numTuples]
     for {set i 0} {$i < $ntups} {incr i} {
         lappend datnames [pg_result $res -getTuple $i]
     }
     pg_result $res -clear
     pg_disconnect $conn
     return $datnames
}

 puts "host 입력"
 gets stdin host
 puts "port 입력"
 gets stdin port
 puts "db명 입력"
 gets stdin db
 puts "user명 입력"
 gets stdin user
 puts "password 입력"
 gets stdin password
 set conn [connectDB $host $port $db $user $password]
 puts "query 입력"
 gets stdin query
 puts [getDBs $conn $query]
