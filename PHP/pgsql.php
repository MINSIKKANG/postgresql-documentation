<?php
  $db_host = "host=127.0.0.1";
  $db_port = "port=5432";

  $db_pw = "user=postgres";
  $db_name = "dbname=postgres";

  $connect_db = pg_connect("$db_host $db_port $db_name $db_pw") or die('Connection Failed');

  $query = 'SELECT * FROM one ORDER BY id';
  $rs = pg_query($connect_db, $query);

  $i = pg_num_fields($rs);
  echo "| ";
  for ($j = 0; $j < $i; $j++) {
      $fieldname = pg_field_name($rs, $j);
      echo "$fieldname |\n";
  }

  echo "<br>\n";
  while($row = pg_fetch_row($rs)){
    echo "| ";
    for ($r = 0; $r < $i; $r++) {
       echo " $row[$r] |";
    }
    echo "<br>\n";
  }

  pg_close($connect_db);
?>