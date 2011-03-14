
<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<%! int num=10; %>


<%
    String tmp=request.getParameter("num");
    if(tmp != null)
        num=Integer.parseInt(tmp);
%>

<html>
  <head><title>Simple jsp page</title></head>
  <body>Test creation of <%=num%> sessions
  <br>

  <%
      for(int i=1; i <= num; i++ ) {
          session=request.getSession(true);
          out.println("<br/>#" + i + ": session id=" + session.getId() + "<br/>");
          session.invalidate();
      }
  %>



  </body>
</html>