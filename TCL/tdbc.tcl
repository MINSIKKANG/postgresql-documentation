package require tdbc::postgres
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

tdbc::postgres::connection create db -host $host -port $port -user $user -password $password -db $db

puts "query 입력"
gets stdin query
db foreach rec $query {
    puts $rec
}
db close
