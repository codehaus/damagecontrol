namespace Nwc.XmlRpc
{
  using System;
  using System.Collections;
  using System.IO;
  using System.Xml;
  using System.Net;
  using System.Text;
  using System.Reflection;
  
  public class XmlRpcRequest
  {
    public String MethodName = null;
    public ArrayList Params = null;
    private Encoding _encoding = new ASCIIEncoding();

    public XmlRpcRequest()
      {
	Params = new ArrayList();
      }

    public String MethodNameObject
      {
	get {
	  int index = MethodName.IndexOf(".");

	  if (index == -1)
	    return MethodName;

	  return MethodName.Substring(0,index);
	}
      }

    public String MethodNameMethod
      {
	get {
	  int index = MethodName.IndexOf(".");

	  if (index == -1)
	    return MethodName;

	  return MethodName.Substring(index + 1, MethodName.Length - index - 1);
	}
      }

    public XmlRpcResponse Send(String url)
      {
	HttpWebRequest request = (HttpWebRequest)WebRequest.Create(url);
	request.Method = "POST";
	request.ContentType = "text/xml";
	
	Stream stream = request.GetRequestStream();
	XmlTextWriter xml = new XmlTextWriter(stream, _encoding);
	XmlRpcRequestSerializer.Serialize(xml, this);
	xml.Flush();
	xml.Close();

	HttpWebResponse response = (HttpWebResponse)request.GetResponse();
	StreamReader input = new StreamReader(response.GetResponseStream());

	XmlRpcResponse resp = XmlRpcResponseDeserializer.Parse(input);
	input.Close();
	response.Close();
	return resp;
      }

    public Object Invoke(Object target)
      {
	Type type = target.GetType();
	MethodInfo method = type.GetMethod(MethodNameMethod);

	if (method == null)
	  throw new XmlRpcException(-2,"Method " + MethodNameMethod + " not found.");

	if (XmlRpcExposedAttribute.IsExposed(target.GetType()) && 
	    !XmlRpcExposedAttribute.IsExposed(method))
	  throw new XmlRpcException(-3, "Method " + MethodNameMethod + " is not exposed.");

	Object[] args = new Object[Params.Count];

	for (int i = 0; i < Params.Count; i++)
	  args[i] = Params[i];

	return method.Invoke(target, args);
      }

    override public String ToString()
      {
	StringWriter strBuf = new StringWriter();
	XmlTextWriter xml = new XmlTextWriter(strBuf);
	xml.Formatting = Formatting.Indented;
	xml.Indentation = 4;
	XmlRpcRequestSerializer.Serialize(xml,this);
	xml.Flush();
	xml.Close();
	return strBuf.ToString();
      }
  }
}
