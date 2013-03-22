<%@ page import="java.net.InetAddress" %>
<%@ page import="java.util.*" %>
<%@ page import="javax.management.*" %>

<%!
    String hostname="n/a", user_name="n/a";
    String nodeName = System.getProperty("jboss.jvmRoute");
    boolean doInvalidation=false;
%>

<%!

    protected static MBeanServer getMBeanServer() {
        ArrayList servers = MBeanServerFactory.findMBeanServer(null);
        if (servers != null && !servers.isEmpty()) {
            // return 'jboss' server if available
            for (int i = 0; i < servers.size(); i++) {
                MBeanServer srv = (MBeanServer) servers.get(i);
                if ("jboss".equalsIgnoreCase(srv.getDefaultDomain()))
                    return srv;
            }

            // return first available server
            return (MBeanServer) servers.get(0);
        }
        else {
            //if it all fails, create a default
            return MBeanServerFactory.createMBeanServer();
        }
    }

    protected String getContext() {
        return getServletConfig().getServletContext().getContextPath();
    }



    static String getClusterView() {
        MBeanServer mbean_server=getMBeanServer();
        ObjectName query=null;
        String retval="n/a";
        Set<String> addrs=new HashSet<String>();
        try {
            query=new ObjectName("jboss:partition=*,service=HAPartition");
            Set<ObjectName> names=mbean_server.queryNames(query, null);
            for(ObjectName name: names) {
                List<String> view=(List<String>)mbean_server.getAttribute(name, "CurrentView");
                if(view != null)
                    addrs.addAll(view);
            }
            if(!addrs.isEmpty()) {
                StringBuilder sb=new StringBuilder();
                boolean first=true;
                for(String addr: addrs) {
                    if(first)
                        first=false;
                    else
                        sb.append(", ");
                    sb.append(addr);
                }
                retval=sb.toString();
            }
        }
        catch (Exception e) {
            e.printStackTrace(System.err);
            retval=e.toString();
        }
        return retval;
    }


    String getClusterView2() {
        // return _getClusterView2("jboss.jgroups:type=channel,cluster=*RelayWeb*");
        return _getClusterView2("jboss.jgroups:type=channel,cluster=*" + getContext() + "*");
    }

   /* String getClusterView3() {
        // return _getClusterView2("jboss.jgroups:type=channel,cluster=*TunnelWeb*");
        return _getClusterView2("jboss.jgroups:type=channel,cluster=*" + getContext() + "*");
    }*/

    protected static String _getClusterView2(String name) {
        MBeanServer mbean_server=getMBeanServer();
        ObjectName query=null;
        try {
            query=new ObjectName(name);
            Set<ObjectName> names=mbean_server.queryNames(query, null);
            if(names.isEmpty())
                return null;
            StringBuilder sb=new StringBuilder();
            boolean first=true;
            for(ObjectName mbean_name: names) {
                String view=(String)mbean_server.getAttribute(mbean_name, "View");
                if(first)
                    first=false;
                else
                    sb.append(", ");
                if(view != null)
                    sb.append(view);
            }
            return sb.toString();
        }
        catch (Exception e) {
            e.printStackTrace(System.err);
            return e.toString();
        }
    }

    protected String getAddress() {
        return _getAddress("jboss.jgroups:type=channel,cluster=*" + getContext() + "*");
    }

    protected static String _getAddress(String name) {
        MBeanServer mbean_server=getMBeanServer();
        ObjectName query=null;
        try {
            query=new ObjectName(name);
            Set<ObjectName> names=mbean_server.queryNames(query, null);
            if(names.isEmpty())
                return null;
            StringBuilder sb=new StringBuilder();
            boolean first=true;
            for(ObjectName mbean_name: names) {
                String local_addr=(String)mbean_server.getAttribute(mbean_name, "Address");
                if(first)
                    first=false;
                else
                    sb.append(", ");
                if(local_addr != null)
                    sb.append(local_addr);
            }
            return sb.toString();
        }
        catch (Exception e) {
            e.printStackTrace(System.err);
            return e.toString();
        }
    }

%>

<%
    //    response.setHeader("Cache-Control", "no-cache");

    response.setHeader("X-ClusterNode", nodeName);

    // Touch the session to ensure cookie is sent
    session.getId();

    doInvalidation=false;
    String action=request.getParameter("action");
    String key=request.getParameter("key"), val=request.getParameter("value");
    if(action != null && action.equals("Invalidate Session")) {
        doInvalidation=true;
    }
    else if(key != null) {
        if(val == null || val.trim().isEmpty()) {
            session.removeAttribute(key);
        }
        else {
            System.out.println("adding " + key + "=" + val);
            session.setAttribute(key, val);
        }
    }
%>

<%
    try {
        hostname=InetAddress.getLocalHost().getHostName();
    }
    catch(Throwable t) {
    }
    try {
        user_name=System.getProperty("user.name", "n/a");
    }
    catch(Throwable t) {}
%>

<html>

<head>
    <title> Session information</title>
</head>

<body bgcolor="white">
<hr>

<br/>

<%!
int number_of_attrs=0, total_size=0;
%>

<%
    number_of_attrs=total_size=0;
    for(Enumeration en=session.getAttributeNames(); en.hasMoreElements();) {
        number_of_attrs++;
        en.nextElement();
    }

    String cluster_view=getClusterView2();
    if(cluster_view == null)
        cluster_view=getClusterView(); // get it from HAPartition
%>

<font size=5> Session information (user=<%=user_name%>, host=<%=hostname%>):<br/><br/>
    Session ID:    <b><%= session.getId() %></b><br/>
    Created: <b><%= new java.util.Date(session.getCreationTime())%></b><br/>
    Last accessed: <b><%= new java.util.Date(session.getLastAccessedTime())%></b><br/>
    Served From:   <b><%= request.getServerName() %>:<%= request.getServerPort() %></b><br/>
    Executed On Server: <b><%= java.net.InetAddress.getLocalHost().getHostName() %> (<%= java.net.InetAddress.getLocalHost().getHostAddress() %>)</b><br/>
    Cluster view: <b><%= cluster_view %></b><br/>
    Local address: <b><%=getAddress()%></b><br/>
    Servlet context: <b><%= getContext()%></b><br/>
    Attributes: <b><%= number_of_attrs%></b><br/>
</font>

<br/>

<%
    ServletContext ctx=session.getServletContext();
    Integer hits=(Integer)ctx.getAttribute("hits");
    if(hits == null) {
        hits=0;
        ctx.setAttribute("hits", hits);
    }
    ctx.setAttribute("hits",hits + 1);
%>

<%=hits%> hits
<br/>
<br/>

<hr><br>
<B>Data retrieved from the HttpSession: </B>
<% 
    java.util.Enumeration valueNames = session.getAttributeNames();
    if (!valueNames.hasMoreElements()) {
    } else {
        out.println("<UL>");
        while (valueNames.hasMoreElements()) {
            String param = (String) valueNames.nextElement();
            String value = session.getAttribute(param).toString();
            out.println("<LI>" + param + " = " + value + "</LI>");
        }
        out.println("</UL>");
    }
%>
<hr/><br/>

<%
   if(doInvalidation) {
        session.invalidate();
        out.println("<br/>Session was invalidated - reload to get new session<br/><br/>");
   }
%>


<B> Add to current session: </B><BR>
<FORM ACTION="index.jsp" METHOD="POST" NAME="AddForm">
    Name:  <INPUT TYPE="text" SIZE="20" NAME="key">
    <BR>
    Value: <INPUT TYPE="text" SIZE="20" NAME="value">
    <br/><br/>
    <INPUT TYPE="submit" NAME="action" VALUE="Add to session">
    <INPUT TYPE="submit" NAME="action" VALUE="Invalidate Session">
</FORM>

</body>
</html>
