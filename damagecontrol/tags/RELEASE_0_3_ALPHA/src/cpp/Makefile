#g++ -o dctrigger Trigger.cpp 

all: dctrigger

clean:
	rm -f Trigger.o dctrigger

dctrigger: Trigger.o
	$(LINK.o) $(OUTPUT_OPTION) $<

Trigger.o: Trigger.cpp Trigger.h
