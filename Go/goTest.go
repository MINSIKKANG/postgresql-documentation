package main

import (
    "database/sql"
    "fmt"
    _ "github.com/lib/pq"
    "bufio"
    "os"
    "strings"
)

/*
const (
    DB_USER     = "postgres"
    DB_PASSWORD = "1234"
    DB_NAME     = "tmax"
    DB_PORT	= "5432"
    DB_HOST     = "127.0.0.1"
)
*/

func main() {
    var tableName string
    var schemaName string
    var colTable map[int] string
    colTable = make(map[int] string)

    var DB_USER     = "tmax"
    var DB_PASSWORD = "1234"
    var DB_NAME     = "tmax"
    var DB_PORT     = "5432"
    var DB_HOST     = "127.0.0.1"

    fmt.Print("\nInput Database HOST : ")
    fmt.Scan(&DB_HOST)
    fmt.Println()

    fmt.Print("Input Database PORT : ")
    fmt.Scan(&DB_PORT)
    fmt.Println()

    fmt.Print("Input Database Name : ")
    fmt.Scan(&DB_NAME)
    fmt.Println()

    fmt.Print("Input Database User : ")
    fmt.Scan(&DB_USER)
    fmt.Println()

    fmt.Print("Input Database PASSWORD : ")
    fmt.Scan(&DB_PASSWORD)
    fmt.Println()

    dbinfo := fmt.Sprintf("user=%s password=%s dbname=%s host=%s port=%s sslmode=disable",
        DB_USER, DB_PASSWORD, DB_NAME, DB_HOST, DB_PORT)

    db, err := sql.Open("postgres", dbinfo)
    if err != nil {
        panic(err)
    }

    fmt.Sprintf("Connected to Database %s:%s/%s \n", DB_HOST, DB_PORT, DB_NAME)

    fmt.Print("Input SELECT QUERY : ")
    inputLine := bufio.NewReader(os.Stdin)
    inputQuery, err := inputLine.ReadString('\n')

    parser(&inputQuery, &tableName, &schemaName)

    metaQuery := "SELECT column_name FROM information_schema.columns WHERE table_name= $1 and table_schema = $2 "
    //RUN
    columns, errs := db.Query(metaQuery,tableName, schemaName)
    if errs != nil {
        panic(errs)
    }
    defer columns.Close()
    var counts = 0
    for columns.Next() {
        var cname string

        columns.Scan(&cname)
        colTable[counts] = cname
        counts++
    }

    for i:= 0; i < counts; i++ {
        fmt.Print(colTable[i])
        if i != counts-1 {
            fmt.Print(" | ")
        } else {
            fmt.Println()
        }
    }
    dataInterface := make([]interface{}, counts)
    Data := make([]string, counts)

    for i, _ := range Data{
        dataInterface[i] = &Data[i]
    }

    rows, err := db.Query(inputQuery)
    if err != nil {
        panic(err)
    }
    defer rows.Close()

    for rows.Next() {
        rows.Scan(dataInterface...)
        for i:= 0; i < counts; i++ {
            if(i != counts-1){
                fmt.Print(Data[i])
                fmt.Print(", ")
            } else {
                fmt.Println(Data[i])
            }
        }
    }

    defer db.Close()
}

func parser(inQ *string, tbn *string, scn *string) {
    low := strings.ToLower(*inQ)
    fromIndex := strings.Index(low,"from")
    slice := low[fromIndex+5:len(low)-1]

    var tbname string
    if strings.IndexAny(slice," ") > 0 {
       tbname = slice[:strings.IndexAny(slice," ")]
    } else {
        tbname = slice[:len(slice)]
    }

    if strings.Contains(tbname,"."){
        *scn = tbname[:strings.Index(tbname,".")]
        *tbn = tbname[strings.Index(tbname,".")+1:len(tbname)]
    } else {
        *tbn = tbname
    }

    if *scn == "" {
        *scn = "public"
    }
}