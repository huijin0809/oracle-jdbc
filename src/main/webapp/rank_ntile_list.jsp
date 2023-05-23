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
	
	// 순위 (분석) 함수 // partition by ... order by ...(+ windowing ... )
	// windowing 절은 디폴트값을 사용 // 디폴트값은 자기 파티션의 처음부터 현재까지
	/*
		SELECT 번호, 사원이름, 급여, 순위
		FROM
		    (SELECT
		        rownum 번호, 사원이름, 급여, 순위
		    FROM
		        (SELECT
		            first_name 사원이름,
		            salary 급여,
		            RANK() OVER(ORDER BY salary) 순위
		        FROM employees))
		WHERE 번호 BETWEEN 1 AND 10;
	*/
	// 1) RANK
	String rankSql = "SELECT 번호, 사원이름, 급여, 순위 FROM (SELECT rownum 번호, 사원이름, 급여, 순위 FROM (SELECT first_name 사원이름, salary 급여, RANK() OVER(ORDER BY salary) 순위 FROM employees)) WHERE 번호 BETWEEN ? AND ?";
	PreparedStatement rankStmt = conn.prepareStatement(rankSql);
	rankStmt.setInt(1, beginRow);
	rankStmt.setInt(2, endRow);
	ResultSet rankRs = rankStmt.executeQuery();
	// HashMap과 ArrayList 이용
	ArrayList<HashMap<String, Object>> rankList = new ArrayList<>();
	while(rankRs.next()) {
		HashMap<String, Object> m = new HashMap<>();
		m.put("번호", rankRs.getInt("번호"));
		m.put("사원이름", rankRs.getString("사원이름"));
		m.put("급여", rankRs.getInt("급여"));
		m.put("순위", rankRs.getInt("순위"));
		rankList.add(m);
	}
	// 2) DENSE_RANK
	String denseRankSql = "SELECT 번호, 사원이름, 급여, 순위 FROM (SELECT rownum 번호, 사원이름, 급여, 순위 FROM (SELECT first_name 사원이름, salary 급여, DENSE_RANK() OVER(ORDER BY salary) 순위 FROM employees)) WHERE 번호 BETWEEN ? AND ?";
	PreparedStatement denseRankStmt = conn.prepareStatement(denseRankSql);
	denseRankStmt.setInt(1, beginRow);
	denseRankStmt.setInt(2, endRow);
	ResultSet denseRankRs = denseRankStmt.executeQuery();
	// HashMap과 ArrayList 이용
	ArrayList<HashMap<String, Object>> denseRankList = new ArrayList<>();
	while(denseRankRs.next()) {
		HashMap<String, Object> m2 = new HashMap<>();
		m2.put("번호", denseRankRs.getInt("번호"));
		m2.put("사원이름", denseRankRs.getString("사원이름"));
		m2.put("급여", denseRankRs.getInt("급여"));
		m2.put("순위", denseRankRs.getInt("순위"));
		denseRankList.add(m2);
	}
	// 3) ROW_NUMBER 
	String rowNumberSql = "SELECT 번호, 사원이름, 급여, 순위 FROM (SELECT rownum 번호, 사원이름, 급여, 순위 FROM (SELECT first_name 사원이름, salary 급여, ROW_NUMBER() OVER(ORDER BY salary) 순위 FROM employees)) WHERE 번호 BETWEEN ? AND ?";
	PreparedStatement rowNumberStmt = conn.prepareStatement(rowNumberSql);
	rowNumberStmt.setInt(1, beginRow);
	rowNumberStmt.setInt(2, endRow);
	ResultSet rowNumberRs = rowNumberStmt.executeQuery();
	// HashMap과 ArrayList 이용
	ArrayList<HashMap<String, Object>> rowNumberList = new ArrayList<>();
	while(rowNumberRs.next()) {
		HashMap<String, Object> m3 = new HashMap<>();
		m3.put("번호", rowNumberRs.getInt("번호"));
		m3.put("사원이름", rowNumberRs.getString("사원이름"));
		m3.put("급여", rowNumberRs.getInt("급여"));
		m3.put("순위", rowNumberRs.getInt("순위"));
		rowNumberList.add(m3);
	}
	// 4) NTILE(숫자) // 분석 비율 함수 
	String ntileSql = "SELECT 번호, 사원이름, 급여, 등급 FROM (SELECT rownum 번호, 사원이름, 급여, 등급 FROM (SELECT first_name 사원이름, salary 급여, NTILE(3) OVER(ORDER BY salary) 등급 FROM employees)) WHERE 번호 BETWEEN ? AND ?";
	PreparedStatement ntileStmt = conn.prepareStatement(ntileSql);
	ntileStmt.setInt(1, beginRow);
	ntileStmt.setInt(2, endRow);
	ResultSet ntileRs = ntileStmt.executeQuery();
	// HashMap과 ArrayList 이용
	ArrayList<HashMap<String, Object>> ntileList = new ArrayList<>();
	while(ntileRs.next()) {
		HashMap<String, Object> m4 = new HashMap<>();
		m4.put("번호", ntileRs.getInt("번호"));
		m4.put("사원이름", ntileRs.getString("사원이름"));
		m4.put("급여", ntileRs.getInt("급여"));
		m4.put("등급", ntileRs.getInt("등급"));
		ntileList.add(m4);
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
<title>rank_ntile_list.jsp</title>
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
			<h1>RANK</h1>
			<h6>동일한 값이면 중복 순위를 부여하고,<br>다음 순위는 해당 개수만큼 건너뛰고 반환</h6>
			<table>
				<tr>
					<th>번호</th>
					<th>사원이름</th>
					<th>급여</th>
					<th>순위</th>
				</tr>
				<%
					for(HashMap<String, Object> m : rankList) {
				%>
						<tr>
							<td><%=(Integer)m.get("번호")%>
							<td><%=(String)m.get("사원이름")%></td>
							<td><%=(Integer)m.get("급여")%></td>
							<td><%=(Integer)m.get("순위")%></td>
						</tr>
				<%
					}
				%>
			</table>
		</div>
		<div class="col">
			<h1>DENSE_RANK</h1>
			<h6>동일한 값이면 중복 순위를 부여하고,<br>다음 순위는 중복 순위와 관계없이<br>순차적으로 반환</h6>
			<table>
				<tr>
					<th>번호</th>
					<th>사원이름</th>
					<th>급여</th>
					<th>순위</th>
				</tr>
				<%
					for(HashMap<String, Object> m2 : denseRankList) {
				%>
						<tr>
							<td><%=(Integer)m2.get("번호")%>
							<td><%=(String)m2.get("사원이름")%></td>
							<td><%=(Integer)m2.get("급여")%></td>
							<td><%=(Integer)m2.get("순위")%></td>
						</tr>
				<%
					}
				%>
			</table>
		</div>
		<div class="col">
			<h1>ROW_NUMBER</h1>
			<h6>중복 순위를 부여하지 않고<br>순차적으로 순위를 반환</h6>
			<table>
				<tr>
					<th>번호</th>
					<th>사원이름</th>
					<th>급여</th>
					<th>순위</th>
				</tr>
				<%
					for(HashMap<String, Object> m3 : rowNumberList) {
				%>
						<tr>
							<td><%=(Integer)m3.get("번호")%>
							<td><%=(String)m3.get("사원이름")%></td>
							<td><%=(Integer)m3.get("급여")%></td>
							<td><%=(Integer)m3.get("순위")%></td>
						</tr>
				<%
					}
				%>
			</table>
		</div>
		<div class="col">
			<h1>NTILE</h1>
			<h6>전체를 숫자만큼 집단으로<br>나누어서 등급을 부여</h6>
			<table>
				<tr>
					<th>번호</th>
					<th>사원이름</th>
					<th>급여</th>
					<th>등급</th>
				</tr>
				<%
					for(HashMap<String, Object> m4 : ntileList) {
				%>
						<tr>
							<td><%=(Integer)m4.get("번호")%>
							<td><%=(String)m4.get("사원이름")%></td>
							<td><%=(Integer)m4.get("급여")%></td>
							<td><%=(Integer)m4.get("등급")%></td>
						</tr>
				<%
					}
				%>
			</table>
		</div>
	</div>
	<div class="text-center">
		<!-- rowPerPage 선택 form -->
		<form action="<%=request.getContextPath()%>/rank_ntile_list.jsp" method="post">
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
				<a href="<%=request.getContextPath()%>/rank_ntile_list.jsp?currentPage=<%=beginPage - 1%>&rowPerPage=<%=rowPerPage%>">이전</a>
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
					<a href="<%=request.getContextPath()%>/rank_ntile_list.jsp?currentPage=<%=i%>&rowPerPage=<%=rowPerPage%>"><%=i%></a>&nbsp;
		<%
				}
			}
		%>
		
		<%
			// 다음은 마지막 페이지에서는 출력되면 안 된다
			if(endPage != lastPage) {
		%>
				<a href="<%=request.getContextPath()%>/rank_ntile_list.jsp?currentPage=<%=endPage + 1%>&rowPerPage=<%=rowPerPage%>">다음</a>
		<%
			}
		%>
	</div>
</body>
</html>