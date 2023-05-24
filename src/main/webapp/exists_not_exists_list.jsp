<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%
	// 1. 요청값 검사
	// currentPage
	int currentPage = 1;
	if(request.getParameter("currentPage") != null) {
		currentPage = Integer.parseInt(request.getParameter("currentPage"));
	}
	System.out.println(currentPage + " <- currentPage");
	// rowPerPage
	int rowPerPage = 10;
	if (request.getParameter("rowPerPage") != null) {
		rowPerPage = Integer.parseInt(request.getParameter("rowPerPage"));
	}
	System.out.println(rowPerPage + " <- rowPerPage");
	
	// 2. 모델값
	// 드라이버 로딩 및 db 접속
	String driver = "oracle.jdbc.driver.OracleDriver";
	Class.forName(driver);
	String dburl = "jdbc:oracle:thin:@localhost:1521:xe";
	String dbuser = "hr";
	String dbpw = "java1234";
	Connection conn = DriverManager.getConnection(dburl, dbuser, dbpw);
	
	// 2-1. 데이터 출력 모델
	/*
		currentPage		beginRow(시작글번호)		endRow(끝글번호)		rowPerpage
		1				1						10					10
		2				11						20					10
		3				21						30					10
		4				31						40					10
	*/
	int endRow = currentPage * rowPerPage;
	int beginRow = endRow - (rowPerPage - 1);
	// 출력할 데이터의 총 갯수
	int totalRow = 0;
	String totalRowSql = "SELECT COUNT(*) FROM employees";
	PreparedStatement totalRowStmt = conn.prepareStatement(totalRowSql);
	ResultSet totalRowRs = totalRowStmt.executeQuery();
	if(totalRowRs.next()) {
		totalRow = totalRowRs.getInt(1);
	}
	// endRow는 totalRow보다 클 수 없다
	if(endRow > totalRow) {
		endRow = totalRow;
	}
	System.out.println(beginRow + " <-beginRow");
	System.out.println(endRow + " <-endRow");
	System.out.println(totalRow + " <-totalRow");
	
	/*
		select 번호, 직원아이디, 사원이름
		from
		    (select rownum 번호, 직원아이디, 사원이름
		    from
		        (select e.employee_id 직원아이디, e.first_name 사원이름
		        from employees e
		        where exists (select * from departments d where d.department_id = e.department_id)))
		where 번호 between ? and ?;
	*/
	// 1) EXISTS
	String existsSql = "SELECT 번호, 직원아이디, 사원이름 FROM (SELECT rownum 번호, 직원아이디, 사원이름 FROM (SELECT e.employee_id 직원아이디, e.first_name 사원이름 FROM employees e WHERE EXISTS (SELECT * FROM departments d WHERE d.department_id = e.department_id))) WHERE 번호 BETWEEN ? AND ?";
	PreparedStatement existsStmt = conn.prepareStatement(existsSql);
	existsStmt.setInt(1, beginRow);
	existsStmt.setInt(2, endRow);
	ResultSet existsRs = existsStmt.executeQuery();
	// HashMap과 ArrayList 이용
	ArrayList<HashMap<String, Object>> existsList = new ArrayList<>();
	while(existsRs.next()) {
		HashMap<String, Object> m = new HashMap<>();
		m.put("번호", existsRs.getInt("번호"));
		m.put("직원아이디", existsRs.getInt("직원아이디"));
		m.put("사원이름", existsRs.getString("사원이름"));
		existsList.add(m);
	}
	// 2) NOT EXISTS
	String notExistsSql = "SELECT 번호, 직원아이디, 사원이름 FROM (SELECT rownum 번호, 직원아이디, 사원이름 FROM (SELECT e.employee_id 직원아이디, e.first_name 사원이름 FROM employees e WHERE NOT EXISTS (SELECT * FROM departments d WHERE d.department_id = e.department_id))) WHERE 번호 BETWEEN ? AND ?";
	PreparedStatement notExistsStmt = conn.prepareStatement(notExistsSql);
	notExistsStmt.setInt(1, beginRow);
	notExistsStmt.setInt(2, endRow);
	ResultSet notExistsRs = notExistsStmt.executeQuery();
	// HashMap과 ArrayList 이용
	ArrayList<HashMap<String, Object>> notExistsList = new ArrayList<>();
	while(notExistsRs.next()) {
		HashMap<String, Object> m = new HashMap<>();
		m.put("번호", notExistsRs.getInt("번호"));
		m.put("직원아이디", notExistsRs.getInt("직원아이디"));
		m.put("사원이름", notExistsRs.getString("사원이름"));
		notExistsList.add(m);
	}
		
	// 2-2. 페이지 출력 모델
	int pagePerPage = 10; // 몇 페이지씩 출력할지 지정
	/*
		currentPage		beginPage		endPage		pagePerPage
		1				1				10			10
		2				1				10			10
		~10				1				10			10
		
		11				11				20			10
		12				11				20			10
		~20				11				20			10
		
		21				21				30			10
		22				21				30			10
		~30				21				30			10
	*/
	int beginPage = (((currentPage - 1) / pagePerPage) * pagePerPage) + 1;
	int endPage = beginPage + (pagePerPage - 1);
	// 마지막 페이지 넘버
	int lastPage = totalRow / rowPerPage;
	if(totalRow % rowPerPage != 0) { // 나누어떨어지지 않으면
		lastPage = lastPage + 1; // 꽉 채워지지 않은 페이지 1개 추가 발생
	}
	// endPage는 lastPage보다 클 수 없다
	if(endPage > lastPage) {
		endPage = lastPage;
	}
	System.out.println(beginPage + " <-beginPage");
	System.out.println(endPage + " <-endPage");
	System.out.println(lastPage + " <-lastPage");
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>exists_not_exists_list.jsp</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.2.3/dist/css/bootstrap.min.css" rel="stylesheet">
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.2.3/dist/js/bootstrap.bundle.min.js"></script>
<style>
	table, th, td {border: 1px solid #000000; text-align: center;}
	table {border-collapse: collapse;}
</style>
</head>
<body>
	<!-- 데이터 출력 모델 -->
	<div class="row">
		<div class="col">
			<h1>EXISTS</h1>
			<h6>서브쿼리의 결과가 한 건이라도 존재하면 true를 반환</h6>
			<table>
				<tr>
					<th>번호</th>
					<th>직원아이디</th>
					<th>사원이름</th>
				</tr>
				<%
					for(HashMap<String, Object> m : existsList) {
				%>
						<tr>
							<td><%=(Integer)m.get("번호")%>
							<td><%=(Integer)m.get("직원아이디")%></td>
							<td><%=(String)m.get("사원이름")%></td>
						</tr>
				<%
					}
				%>
			</table>
		</div>
		<div class="col">
			<h1>NOT EXISTS</h1>
			<h6>서브쿼리의 결과가 한 건이라도 존재하지 않으면 해당 레코드를 출력</h6>
			<table>
				<tr>
					<th>번호</th>
					<th>직원아이디</th>
					<th>사원이름</th>
				</tr>
				<%
					for(HashMap<String, Object> m2 : notExistsList) {
				%>
						<tr>
							<td><%=(Integer)m2.get("번호")%>
							<td><%=(Integer)m2.get("직원아이디")%></td>
							<td><%=(String)m2.get("사원이름")%></td>
						</tr>
				<%
					}
				%>
			</table>
		</div>
	</div>
	<div class="text-center">
		<!-- rowPerPage 선택 form -->
		<form action="<%=request.getContextPath()%>/exists_not_exists_list.jsp" method="post">
			<select name="rowPerPage" onchange="this.form.submit()"> <!-- 옵션 선택시 바로 submit -->
				<%
					for (int i = 5; i <= 50; i = i + 5) {
				%>
						<option value="<%=i%>" <%if (rowPerPage == i) {%> selected <%}%>>
							<%=i%>개씩
						</option>
				<%
					}
				%>
			</select>
		</form>
		<!-- 페이지 출력 모델 -->
		<%
			// 이전은 1페이지에서는 출력되면 안 된다
			if(beginPage != 1) {
		%>
				<a href="<%=request.getContextPath()%>/exists_not_exists_list.jsp?currentPage=<%=beginPage - 1%>&rowPerPage=<%=rowPerPage%>">이전</a>
		<%
			}
		%>
		
		<%
			for(int i = beginPage; i <= endPage; i++) {
				if(i == currentPage) { // 현재페이지에서는 a태그 없이 출력
		%>
					<span><%=i%></span>&nbsp;
		<%
				} else {
		%>
					<a href="<%=request.getContextPath()%>/exists_not_exists_list.jsp?currentPage=<%=i%>&rowPerPage=<%=rowPerPage%>"><%=i%></a>&nbsp;
		<%
				}
			}
		%>
		
		<%
			// 다음은 마지막 페이지에서는 출력되면 안 된다
			if(endPage != lastPage) {
		%>
				<a href="<%=request.getContextPath()%>/exists_not_exists_list.jsp?currentPage=<%=endPage + 1%>&rowPerPage=<%=rowPerPage%>">다음</a>
		<%
			}
		%>
	</div>
</body>
</html>