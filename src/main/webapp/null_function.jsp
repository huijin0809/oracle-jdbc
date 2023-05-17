<%@page import="oracle.jdbc.proxy.annotation.Pre"%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%
	// 드라이버 로딩 및 db접속
	String driver = "oracle.jdbc.driver.OracleDriver";
	Class.forName(driver);
	String dburl = "jdbc:oracle:thin:@localhost:1521:xe";
	String dbuser = "sqld2";
	String dbpw = "java1234";
	Connection conn = DriverManager.getConnection(dburl, dbuser, dbpw);
	System.out.println(conn);
	
	// null값 처리 함수
	// 1) nvl
	String nvlSql = "SELECT 이름, NVL(일분기, 0) 결과 FROM 실적";
	PreparedStatement nvlStmt = conn.prepareStatement(nvlSql);
	ResultSet nvlRs = nvlStmt.executeQuery();
	// HashMap과 ArrayList를 사용하여 출력
	ArrayList<HashMap<String, Object>> nvlList = new ArrayList<>();
	while(nvlRs.next()) {
		HashMap<String, Object> n = new HashMap<>();
		n.put("이름", nvlRs.getString("이름"));
		n.put("결과", nvlRs.getInt("결과"));
		nvlList.add(n);
	}
	System.out.println(nvlList.size() + " <- nvlList.size()");
	
	// 2) nvl2
	String nvl2Sql = "SELECT 이름, NVL2(일분기, 'success', 'fail') 결과 FROM 실적";
	PreparedStatement nvl2Stmt = conn.prepareStatement(nvl2Sql);
	ResultSet nvl2Rs = nvl2Stmt.executeQuery();
	// HashMap, ArrayList
	ArrayList<HashMap<String, Object>> nvl2List = new ArrayList<>();
	while(nvl2Rs.next()) {
		HashMap<String, Object> n2 = new HashMap<>();
		n2.put("이름", nvl2Rs.getString("이름"));
		n2.put("결과", nvl2Rs.getString("결과"));
		nvl2List.add(n2);
	}
	System.out.println(nvl2List.size() + " <- nvl2List.size()");
	
	// 3) nullif
	String nullifSql = "SELECT 이름, NULLIF(사분기, 100) 결과 FROM 실적";
	PreparedStatement nullifStmt = conn.prepareStatement(nullifSql);
	ResultSet nullifRs = nullifStmt.executeQuery();
	// HashMap, ArrayList
	ArrayList<HashMap<String, Object>> nullifList = new ArrayList<>();
	while(nullifRs.next()) {
		HashMap<String, Object> n3 = new HashMap<>();
		n3.put("이름", nullifRs.getString("이름"));
		n3.put("결과", nullifRs.getInt("결과"));
		nullifList.add(n3);
	}
	System.out.println(nullifList.size() + " <- nullifList.size()");
	
	// 4) coalesce
	String coalesceSql = "SELECT 이름, coalesce(일분기, 이분기, 삼분기, 사분기) 결과 FROM 실적";
	PreparedStatement coalesceStmt = conn.prepareStatement(coalesceSql);
	ResultSet coalesceRs = coalesceStmt.executeQuery();
	// HashMap, ArrayList
	ArrayList<HashMap<String, Object>> coalesceList = new ArrayList<>();
	while(coalesceRs.next()) {
		HashMap<String, Object> c = new HashMap<>();
		c.put("이름", coalesceRs.getString("이름"));
		c.put("결과", coalesceRs.getInt("결과"));
		coalesceList.add(c);
	}
	System.out.println(coalesceList.size() + " <- coalesceList.size()");
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>null_function.jsp</title>
<style>
	table, th, td {border: 1px solid #000000; text-align: center;}
	table {border-collapse: collapse;}
</style>
</head>
<body>
	<h3>1. select 이름, nvl(일분기, 0) from 실적</h3>
	<table>
		<%
			for(HashMap<String, Object> n : nvlList) {
		%>
				<tr>
					<td><%=(String)(n.get("이름"))%></td>
					<td><%=(Integer)(n.get("결과"))%></td>
				</tr>
		<%
			}
		%>
	</table>
	
	<h3>2. select 이름, nvl2(일분기, 'success', 'fail') from 실적</h3>
	<table>
		<%
			for(HashMap<String, Object> n2 : nvl2List) {
		%>
				<tr>
					<td><%=(String)(n2.get("이름"))%></td>
					<td><%=(String)(n2.get("결과"))%></td>
				</tr>
		<%
			}
		%>
	</table>
	
	<h3>3. select 이름, nullif(사분기, 100) from 실적</h3>
	<table>
		<%
			for(HashMap<String, Object> n3 : nullifList) {
		%>
				<tr>
					<td><%=(String)(n3.get("이름"))%></td>
					<td><%=(Integer)(n3.get("결과"))%></td>
				</tr>
		<%
			}
		%>
	</table>
	
	<h3>4. select 이름, coalesce(일분기, 이분기, 삼분기, 사분기) from 실적</h3>
	<table>
		<%
			for(HashMap<String, Object> c : coalesceList) {
		%>
				<tr>
					<td><%=(String)(c.get("이름"))%></td>
					<td><%=(Integer)(c.get("결과"))%></td>
				</tr>
		<%
			}
		%>
	</table>
</body>
</html>