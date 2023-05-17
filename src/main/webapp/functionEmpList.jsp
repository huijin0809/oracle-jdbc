<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%
	// 1. 요청값 유효성 검사
	// currentPage
	int currentPage = 1;
	if(request.getParameter("currentPage") != null) {
		currentPage = Integer.parseInt(request.getParameter("currentPage"));
	}

	// 2. 모델값
	// 드라이버 로딩 및 db 접속
	String driver = "oracle.jdbc.driver.OracleDriver";
	Class.forName(driver);
	String dburl = "jdbc:oracle:thin:@localhost:1521:xe";
	String dbuser = "hr";
	String dbpw = "java1234";
	Connection conn = DriverManager.getConnection(dburl, dbuser, dbpw);
	System.out.println(conn);
	
	// 2-1) 데이터 출력 모델값
	int rowPerPage = 10; // 지정값, 데이터를 몇개씩 출력할지
	// 출력할 데이터의 시작,끝 넘버
	int beginRow = (currentPage - 1) * rowPerPage + 1;
	int endRow = beginRow + (rowPerPage - 1);
	// 출력할 데이터의 총 갯수
	int totalRow = 0;
	String totalRowSql = "SELECT count(*) FROM employees";
	PreparedStatement totalRowStmt = conn.prepareStatement(totalRowSql);
	ResultSet totalRowRs = totalRowStmt.executeQuery();
	if(totalRowRs.next()) {
		totalRow = totalRowRs.getInt(1);
	}
	// endRow는 totalRow보다 클 수 없다
	if(endRow > totalRow) {
		endRow = totalRow;
	}
	// 데이터 출력 쿼리
	/*
		select 번호, 이름, 이름첫글자, 연봉, 급여, 입사날짜, 입사년도 
			from
			    (select
			    	rownum 번호,
			    	last_name 이름,
			    	substr(last_name, 1, 1) 이름첫글자,
			    	salary 연봉,
			    	round(salary/12, 2) 급여,
			    	hire_date 입사날짜,
			    	extract(year from hire_date) 입사년도 
			    from employees)
			where 번호 between ? and ?
	*/
	String sql = "SELECT 번호, 이름, 이름첫글자, 연봉, 급여, 입사날짜, 입사년도 FROM (SELECT rownum 번호, last_name 이름, SUBSTR(last_name, 1, 1) 이름첫글자, salary 연봉, ROUND(salary/12, 2) 급여, hire_date 입사날짜, EXTRACT(YEAR FROM hire_date) 입사년도 FROM employees) WHERE 번호 BETWEEN ? AND ?";
	PreparedStatement stmt = conn.prepareCall(sql);
	stmt.setInt(1, beginRow);
	stmt.setInt(2, endRow);
	ResultSet rs = stmt.executeQuery();
	// HashMap, ArrayList를 이용하여 출력
	ArrayList<HashMap<String, Object>> list = new ArrayList<>();
	while(rs.next()) {
		HashMap<String, Object> m = new HashMap<>();
		m.put("번호", rs.getInt("번호"));
		m.put("이름", rs.getString("이름"));
		m.put("이름첫글자", rs.getString("이름첫글자"));
		m.put("연봉", rs.getInt("연봉"));
		m.put("급여", rs.getDouble("급여"));
		m.put("입사날짜", rs.getString("입사날짜"));
		m.put("입사년도", rs.getInt("입사년도"));
		list.add(m);
	}
	System.out.println(list.size() + " <- list.size()");
	
	// 2-2) 페이징 버튼 출력 모델값
	// 페이지 네비게이션 페이징
	/*
		currentPage		minPage		maxpage
		1				1			10
		2				1			10
		~10				1			10
		
		11				11			20
		12				11			20
		~20				11			20
		
		21				21			30
		22				21			30
		~30				21			30
	*/
	int pagePerPage = 10; // 지정값, 페이지 버튼을 몇개씩 출력할지
	// 출력할 페이지 버튼의 시작,끝 넘버
	int minPage = (((currentPage - 1) / pagePerPage) * pagePerPage) + 1;
	int maxPage = minPage + (pagePerPage - 1);
	// 마지막 페이지 넘버
	int lastPage = totalRow / rowPerPage;
	if(totalRow % rowPerPage != 0) { // 나누어떨어지지 않으면
		lastPage = lastPage + 1; // 꽉 채워지지 않는 페이지 추가 발생
	}
	// maxPage는 lastPage보다 클 수 없다
	if(maxPage > lastPage) {
		maxPage = lastPage;
	}
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>functionEmpList.jsp</title>
<style>
	table, th, td {border: 1px solid #000000; text-align: center;}
	table {border-collapse: collapse;}
</style>
</head>
<body>
	<table>
		<tr>
			<td>번호</td>
			<td>이름</td>
			<td>이름첫글자</td>
			<td>연봉</td>
			<td>급여</td>
			<td>입사날짜</td>
			<td>입사년도</td>
		</tr>
		<%
			for(HashMap<String, Object> m : list) {
		%>
				<tr>
					<td><%=(Integer)m.get("번호")%></td>
					<td><%=(String)m.get("이름")%></td>
					<td><%=(String)m.get("이름첫글자")%></td>
					<td><%=(Integer)m.get("연봉")%></td>
					<td><%=(Double)m.get("급여")%></td>
					<td><%=(String)m.get("입사날짜")%></td>
					<td><%=(Integer)m.get("입사년도")%></td>
				</tr>
		<%
			}
		%>
	</table>
	<%
		// 이전은 1페이지에서는 출력되지 않는다
		if(minPage > 1) {
	%>
			<a href="<%=request.getContextPath()%>/functionEmpList.jsp?currentPage=<%=minPage - 1%>">이전</a>
	<%
		}
	%>
	
	<%
		for(int i = minPage; i <= maxPage; i++) {
			if(i == currentPage) { // 현재페이지에서는 a태그 없이 출력
	%>
				<span><%=i%></span>&nbsp;
	<%
			} else {
	%>
				<a href="<%=request.getContextPath()%>/functionEmpList.jsp?currentPage=<%=i%>"><%=i%></a>&nbsp;
	<%
			}
		}
	%>
	
	<%
		// 다음은 lastPage에서는 출력되지 않는다
		if(maxPage != lastPage) {
	%>
			<a href="<%=request.getContextPath()%>/functionEmpList.jsp?currentPage=<%=maxPage + 1%>">다음</a>
	<%
		}
	%>
</body>
</html>