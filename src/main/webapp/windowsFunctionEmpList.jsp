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
	int rowPerPage = 10; // 데이터를 몇개씩 출력할지 지정
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
	
	// 2-1) 데이터 출력부 (상단)
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
	// 데이터 출력 쿼리 작성
	/*
		select 글번호, 사원아이디, 사원이름, 급여, 전체급여평균, 전체급여합계, 전체사원수
			from 
				(select
					rownum 글번호,
					employee_id 사원아이디,
					last_name 사원이름,
					salary 급여,
				    round(avg(salary) over()) 전체급여평균,
				    sum(salary) over() 접체급여합계,
				    count(*) over() 전체사원수
				from employees)
		where 글번호 between ? and ?;
	*/
	String sql = "SELECT 글번호, 사원아이디, 사원이름, 급여, 전체급여평균, 전체급여합계, 전체사원수 FROM(SELECT rownum 글번호, employee_id 사원아이디, last_name 사원이름, salary 급여, ROUND(AVG(salary) OVER()) 전체급여평균, SUM(salary) OVER() 전체급여합계, COUNT(*) OVER() 전체사원수 FROM employees) WHERE 글번호 BETWEEN ? AND ?";
	PreparedStatement stmt = conn.prepareStatement(sql);
	stmt.setInt(1, beginRow);
	stmt.setInt(2, endRow);
	ResultSet rs = stmt.executeQuery();
	// HashMap과 ArrayList를 이용하여 출력
	ArrayList<HashMap<String, Object>> list = new ArrayList<>(); // 두번째 제너릭은 생략 가능
	while(rs.next()) {
		HashMap<String, Object> m = new HashMap<>();
		m.put("글번호", rs.getInt("글번호"));
		m.put("사원아이디", rs.getInt("사원아이디"));
		m.put("사원이름", rs.getString("사원이름"));
		m.put("급여", rs.getInt("급여"));
		m.put("전체급여평균", rs.getInt("전체급여평균"));
		m.put("전체급여합계", rs.getInt("전체급여합계"));
		m.put("전체사원수", rs.getInt("전체사원수"));
		list.add(m);
	}
	System.out.println(list.size() + " <- list.size()");
	
	// 2-2) 페이지 출력부 (하단)
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
<title>windowsFunctionEmpList.jsp</title>
<style>
	table, th, td {border: 1px solid #000000; text-align: center;}
	table {border-collapse: collapse;}
</style>
</head>
<body>
	<h1>windowsFunctionEmpList</h1>
	<form action="<%=request.getContextPath()%>/windowsFunctionEmpList.jsp" method="post">
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
	<!-- 데이터 출력부 -->
	<table>
		<tr>
			<th>글번호</th>
			<th>사원아이디</th>
			<th>사원이름</th>
			<th>급여</th>
			<th>전체급여평균</th>
			<th>전체급여합계</th>
			<th>전체사원수</th>
		</tr>
		<%
			for(HashMap<String, Object> m : list) {
		%>
				<tr>
					<td><%=(Integer)m.get("글번호")%></td>
					<td><%=(Integer)m.get("사원아이디")%></td>
					<td><%=(String)m.get("사원이름")%></td>
					<td><%=(Integer)m.get("급여")%></td>
					<td><%=(Integer)m.get("전체급여평균")%></td>
					<td><%=(Integer)m.get("전체급여합계")%></td>
					<td><%=(Integer)m.get("전체사원수")%></td>
				</tr>
		<%
			}
		%>
	</table>
	<!-- 페이지 출력부 -->
	<%
		// 이전은 1페이지에서는 출력되면 안 된다
		if(beginPage != 1) {
	%>
			<a href="<%=request.getContextPath()%>/windowsFunctionEmpList.jsp?currentPage=<%=beginPage - 1%>&rowPerPage=<%=rowPerPage%>">이전</a>
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
				<a href="<%=request.getContextPath()%>/windowsFunctionEmpList.jsp?currentPage=<%=i%>&rowPerPage=<%=rowPerPage%>"><%=i%></a>&nbsp;
	<%
			}
		}
	%>
	
	<%
		// 다음은 마지막 페이지에서는 출력되면 안 된다
		if(endPage != lastPage) {
	%>
			<a href="<%=request.getContextPath()%>/windowsFunctionEmpList.jsp?currentPage=<%=endPage + 1%>&rowPerPage=<%=rowPerPage%>">다음</a>
	<%
		}
	%>
</body>
</html>