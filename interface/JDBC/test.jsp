<%@page contentType="text/html;charset=utf-8" import="java.sql.*" %>
<%

Connection db = null;
PreparedStatement pstmt = null;
ResultSet rs = null;
int columnCount = 0;

try{
    String url = "jdbc:postgresql://210.106.105.55/postgres"; //데이터베이스 호스트/데이터베이스명
    String user = "postgres"; //유저명
    String pwd = "1234"; //패스워드
    Class.forName("org.postgresql.Driver");
    db = DriverManager.getConnection(url, user, pwd);

    pstmt = db.prepareStatement("SELECT *, convert_from(decrypt(decode(en_first_name, 'hex'), 'test_key', 'aes'), 'utf8') as decrypt FROM one limit 10"); //실행할 쿼리
    rs = pstmt.executeQuery();
    ResultSetMetaData rsmd = rs.getMetaData();
    columnCount = rsmd.getColumnCount();
            
%><table border="1" cellspacing="0">

<tr align="center">
    <% for(int i=1; i<=columnCount; i++) { %>
        <td> <%=rsmd.getColumnName(i)%> </td>
    <%}%>
</tr>
<%
    while(rs.next()){
%>
    <tr>
        <% for(int j=1; j<=columnCount; j++) { %>
	    <% if(rsmd.getColumnClassName(j).contains("Integer")) { %> <td><%=rs.getInt(j)%></td>
	    <% } else  { %> <td><%=rs.getString(j)%></td> <%}%>
	<%}%>
    <%}%>
</tr>
</table>

<%
    if(rs != null) try { rs.close(); } catch(Exception rse){ rse.printStackTrace();}  finally{ rs.close(); };
    if(pstmt != null) try { pstmt.close(); } catch(Exception pste){ pste.printStackTrace();}  finally{ pstmt.close(); };
    if(db != null) try { db.close(); } catch(Exception dbe){ dbe.printStackTrace();}  finally{ db.close(); };
} catch (SQLException e){
    out.println("err:"+e.toString());
}
%>
