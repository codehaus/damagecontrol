
#ifndef TRIGGER_H
#define TRIGGER_H

#ifdef _WIN32

	#include <Winsock2.h>	// Requires Ws2_32.lib
#else

	#include <sys/socket.h>
//	#include <netinet/in.h>
//	#include <arpa/inet.h>
//	#include <sys/types.h>

	#include <unistd.h>
	#include <string.h> // For memcpy
//	#include <fcntl.h>
//	#include <io.h>
	#include <netdb.h>

#endif


#include "stdio.h"
#include "stdlib.h"
#include "time.h"

class Trigger
{
public:

	static bool Active;
	char * Url;
	char * ProjectName;

	Trigger();
	void Process();

};


#endif
