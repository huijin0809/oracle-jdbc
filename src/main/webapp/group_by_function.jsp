<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%
	// 드라이버 로딩 및 db 접속
	String driver = "oracle.jdbc.driver.OracleDriver";
	Class.forName(driver);
	String dburl = "jdbc:oracle:thin:@localhost:1521:xe";
	String dbuser = "hr";
	String dbpw = "java1234";
	Connection conn = DriverManager.getConnection(dburl, dbuser, dbpw);
	System.out.println(conn);
	
	// group by절의 확장 함수
	// 1) grouping sets()
	String setsSql = "SELECT department_id, job_id, count(*) FROM employees GROUP BY GROUPING SETS(department_id, job_id)";
	PreparedStatement setsStmt = conn.prepareStatement(setsSql);
	ResultSet setsRs = setsStmt.executeQuery();
	// 출력을 위해 HashMap과 ArrayList를 사용
	ArrayList<HashMap<String, Object>> setsList = new ArrayList<>();
	while(setsRs.next()) {
		HashMap<String, Object> s = new HashMap<>();
		s.put("departmentId", setsRs.getInt("department_id"));
		s.put("jobId", setsRs.getString("job_id"));
		s.put("cnt", setsRs.getInt("count(*)"));
		setsList.add(s);
	}
	System.out.println(setsList.size() + " <- setsList size()");
	
	// 2) rollup()
	String rollupSql = "SELECT department_id, job_id, count(*) FROM employees GROUP BY ROLLUP(department_id, job_id)";
	PreparedStatement rollupStmt = conn.prepareStatement(rollupSql);
	ResultSet rollupRs = rollupStmt.executeQuery();
	// HashMap, ArrayList
	ArrayList<HashMap<String, Object>> rollupList = new ArrayList<>();
	while(rollupRs.next()){
		HashMap<String, Object> r = new HashMap<>();
		r.put("departmentId", rollupRs.getInt("department_id"));
		r.put("jobId", rollupRs.getString("job_id"));
		r.put("cnt", rollupRs.getInt("count(*)"));
		rollupList.add(r);
	}
	System.out.println(rollupList.size() + " <- rollupList.size()");
	
	// 3) cube()
	String cubeSql = "SELECT department_id, job_id, count(*) FROM employees GROUP BY CUBE(department_id, job_id)";
	PreparedStatement cubeStmt = conn.prepareStatement(cubeSql);
	ResultSet cubeRs = cubeStmt.executeQuery();
	// HashMap, ArrayList
	ArrayList<HashMap<String, Object>> cubeList = new ArrayList<>();
	while(cubeRs.next()){
		HashMap<String, Object> c = new HashMap<>();
		c.put("departmentId", cubeRs.getInt("department_id"));
		c.put("jobId", cubeRs.getString("job_id"));
		c.put("cnt", cubeRs.getInt("count(*)"));
		cubeList.add(c);
	}
	System.out.println(cubeList.size() + " <- cubeList.size()");
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>group_by_function.jsp</title>
<style>
	table, th, td {border: 1px solid #000000; text-align: center;}
	table {border-collapse: collapse;}
</style>
</head>
<body>
	<h1>grouping sets 결과셋</h1>
	<table>
		<tr>
			<th>departmentId</th>
			<th>jobId</th>
			<th>cnt</th>
		</tr>
		<%
			for(HashMap<String, Object> s : setsList) {
		%>
				<tr>
					<td><%=(Integer)(s.get("departmentId"))%></td>
					<td><%=(String)(s.get("jobId"))%></td>
					<td><%=(Integer)(s.get("cnt"))%></td>
				</tr>
		<%
			}
		%>
	</table>
	<h1>roll up 결과셋</h1>
	<table>
		<tr>
			<th>departmentId</th>
			<th>jobId</th>
			<th>cnt</th>
		</tr>
		<%
			for(HashMap<String, Object> r : rollupList) {
		%>
				<tr>
					<td><%=(Integer)(r.get("departmentId"))%></td>
					<td><%=(String)(r.get("jobId"))%></td>
					<td><%=(Integer)(r.get("cnt"))%></td>
				</tr>
		<%
			}
		%>
	</table>
	<h1>cube 결과셋</h1>
	<table>
		<tr>
			<th>departmentId</th>
			<th>jobId</th>
			<th>cnt</th>
		</tr>
		<%
			for(HashMap<String, Object> c : cubeList) {
		%>
				<tr>
					<td><%=(Integer)(c.get("departmentId"))%></td>
					<td><%=(String)(c.get("jobId"))%></td>
					<td><%=(Integer)(c.get("cnt"))%></td>
				</tr>
		<%
			}
		%>
	</table>
</body>
</html>