// c++ implementation of damagecontrol build request trigger.
// can be compiled for any platform and can be made available
// from the path.
//
// use this program if you don't have ruby installed on the
// same machine as your scm. executables are provided for
// win32, cygwin and redhat linux x86. if your scm is on a
// different platform, you should be able to recompile this
// program. patches and binaries are welcome if you want to
// contribute back to the project. due credit will be given.
//
// usage: dctrigger <url> <project_name>
//
// url is the location of damagecontrol's xml-rpc interface
// for build trigging.
//
// project_name is the name of the project for which the build
// is requested. this should correspond to a project configured
// in the damagecontrol server.
//
// this program should be invoked by the scm upon successful
// commits/checkins. it will notify the damagecontrol server
// that the project has changed (and at what utc timestamp
// according to the scm). the server will then get the changes
// up until that timestamp and build (once the request is
// honoured - it might be queued).
//
// damagecontrol will provide easy commands via command line or
// web/gui clients to configure the scm to do that. for further
// information see the scm documentation for how to configure the
// scm to invoke post-commit commands.
//
// the program exits immediately once the message has been sent,
// and no feedback is given back. build status should be checked
// via some of the multiple publishing channels provided by
// damagecontrol.
//
// authors: emerson clarke, aslak hellesoy, trygvis, dan north

#include "Trigger.h"

bool Trigger::Active=false;

Trigger::Trigger()
{
	#ifdef _WIN32
		if (! Active)
		{
			WORD wVersionRequested = MAKEWORD(2,2);
			WSADATA wsaData;
			if ( WSAStartup(wVersionRequested,&wsaData) != 0 )
			{
				fprintf(stdout,"Winsock startup failed");
				WSACleanup();
			}

			Active = true;
		}
	#endif
}

void Trigger::Process()
{
	// parse the url into host, port and path

	int port_start = -1;
	int path_start = -1;

    char * host;
    int port = 80;
    char * path;

	int len = strlen(Url);
	for(int i=7; i<len; i++) {
		switch(Url[i]) {
			case ':':
				Url[i] = 0;
				port_start = i + 1;
				break;
			case '/':
				if(path_start == -1) {
					Url[i] = 0;
					path_start = i + 1;				}
				break;
			default:
				break;
		}
	}
	if(path_start == -1)
	{
		fprintf(stderr,"bad url %s\n", Url );
		exit(1);
	}
	if(port_start != -1)
	{
		port = atoi (Url + port_start);
	}
	path = Url + path_start;
    host = Url + 7;

	// current time in utc (ISO-8601)
	time_t timestamp;
	(void) time(&timestamp);

	struct tm *ptr;
    char time[80];
    ptr = gmtime(&timestamp);  // return time in the form of tm structure
	strftime(time,80,"%Y-%m-%dT%H:%M:%S",ptr);

	// connect to the damagecontrol server
	int sock = socket(PF_INET,SOCK_STREAM,IPPROTO_TCP);
	sockaddr_in address;
	address.sin_family=PF_INET;
	hostent * entry = gethostbyname(host);

	if( !entry ) {
		fprintf(stderr,"bad hostname %s\n", host );
		exit(1);
	}

	address.sin_addr.s_addr = ((in_addr *)entry->h_addr_list[0])->s_addr;
	address.sin_port = htons(port);

	if ( connect(sock,(const sockaddr*)&address,sizeof(sockaddr)) != -1)
	{
		// send the xml-rpc request
		char payload[4096];
		int content_length = sprintf(payload,"<?xml version=\"1.0\"?><methodCall><methodName>build.request_build</methodName><params><param><value><string>%s</string></value></param><param><value><string>%s</string></value></param></params></methodCall>", ProjectName, time);

		char buffer[4096];
		int offset = sprintf(buffer,"POST /%s HTTP/1.0\r\nUser-Agent: DamageControl/Trigger\r\nContent-Type: text/xml\r\nConnection: close\r\nContent-Length: %d\r\n\r\n", path, content_length);
		sprintf(buffer + offset, payload);

		if (send(sock,buffer,strlen(buffer),0) != -1)
		{
			// Read line by line and verify that the HTTP response code is 200.
			// (It will be 200 for both cases below, and something else in case of an XML-RPC error).
			// When we get to the payload (after an empty line), extract the message
			// from the XML (which can be expected to be on one single line). The XML will
			// be of one of the following formats:
			//
			// text to extract: ---------------------------------------------------------------------------------------------------------------------------------------------------------|                                                                                                           |-------------------------------------------------------------------
			// <?xml version="1.0" ?><methodResponse><fault><value><struct><member><name>faultCode</name><value><i4>2</i4></value></member><member><name>faultString</name><value><string>Uncaught exception No such file or directory - /projects/my_project/conf.yaml in method build.request_build</string></value></member></struct></value></fault></methodResponse>
			//
			// text to extract: --------------------------------------------------|                                       |--------------------------------------------------
			// <?xml version="1.0" ?><methodResponse><params><param><value><string>Build has been requested for my_project</string></value></param></params></methodResponse>
			int bytes = 0;
			int len = 0;

			while((len = recv(sock,buffer+bytes,sizeof buffer,0)) > 0) {
				bytes += len;
			}
			buffer[bytes]=0;

			// verify that HTTP code == 200
			buffer [12] = 0;
			int http_code;
			http_code = atoi(buffer + 9);
			if(http_code != 200) {
				fprintf(stdout,"XML-RPC error: %d.\n", http_code);
			}

			// Look for content between <string></string>
			char * start_token = "<string>";
			char * end_token = "</string>";
			int message_start = -1;
			for(int i = 10; i < bytes; i++) {
				if(message_start == -1 && 'g' == buffer[i-2] && '>' == buffer[i-1]) {
					message_start = i;
				}
				if(message_start != -1 && '<' == buffer[i]) {
					buffer[i] = 0;
					break;
				}
			}

			fprintf(stdout,"%s\n", buffer + message_start);
		}
		else
		{
			fprintf(stdout,"Socket error on send.\n");
		}

		#ifdef _WIN32
			closesocket(sock);
		#else
			shutdown(sock,SHUT_RDWR);
		#endif

	}
	else
	{
		fprintf(stdout,"Socket error on connect.\n");
	}
}

int main(int length, char * arguments[])
{
	if (length == 3)
	{
		Trigger trigger;
		trigger.Url = arguments[1];
		trigger.ProjectName = arguments[2];

		trigger.Process();
	}
	else
	{
		fprintf(stdout,"Syntax: dctrigger <url> <project_name>\n");
	}

	return 0;
}
