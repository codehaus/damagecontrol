SOURCES = \
./AssemblyInfo.cs \
./Logger.cs \
./SimpleHttpRequest.cs \
./XmlRpcBoxcarRequest.cs \
./XmlRpcClientProxy.cs \
./XmlRpcDeserializer.cs \
./XmlRpcErrorCodes.cs \
./XmlRpcException.cs \
./XmlRpcExposedAttribute.cs \
./XmlRpcRequest.cs \
./XmlRpcRequestDeserializer.cs \
./XmlRpcRequestSerializer.cs \
./XmlRpcResponder.cs \
./XmlRpcResponse.cs \
./XmlRpcResponseDeserializer.cs \
./XmlRpcResponseSerializer.cs \
./XmlRpcSerializer.cs \
./XmlRpcServer.cs \
./XmlRpcSystemObject.cs \
./XmlRpcXmlTokens.cs

SYSTEM_REFERENCES = \
System.dll \
System.Data.dll \
System.Xml.dll

SYSTEM_REFERENCES_BUILD = $(addprefix -r:, $(SYSTEM_REFERENCES))

SYSTEM_REFERENCES_CHECK = $(addsuffix .check, $(SYSTEM_REFERENCES))

MCS_OPTIONS =

all: XmlRpcCs-win.dll XmlRpcCs-mono.dll

XmlRpcCs-win.dll: $(SOURCES)
	mcs $(MCS_OPTIONS) -target:library -out:"XmlRpcCs-win.dll" $(SYSTEM_REFERENCES_BUILD) $(SOURCES)

XmlRpcCs-mono.dll: $(SOURCES)
	mcs $(MCS_OPTIONS) -target:library -out:"XmlRpcCs-mono.dll" $(SYSTEM_REFERENCES_BUILD) $(SOURCES)

clean:
	rm -f XmlRpcCs-win.dll XmlRpcCs-mono.dll

depcheck: SYSTEM_depcheck

SYSTEM_depcheck: $(SYSTEM_REFERENCES_CHECK)

%.check:
	@echo -n Checking for $(subst .check,,$@)...
	@if [ ! -e `pkg-config --variable=libdir mono`/mono/1.0/$(subst .check,,$@) ]; then \
		echo no; \
		exit 1; \
	else \
		echo yes; \
	fi
