package damagecontrol.testtest;

import damagecontrol.listeners.WriteToFileNotifier;
import damagecontrol.Builder;
import damagecontrol.BuildEvent;

import java.io.FileWriter;
import java.io.IOException;

public class SimpleWriteToFileNotifier extends WriteToFileNotifier{
    public SimpleWriteToFileNotifier(Builder builder, String fileToWriteTo) {
        super(builder, fileToWriteTo);
    }

    protected void writeOutput(FileWriter writer, BuildEvent evt) throws IOException {
        writer.write(evt.getOutput());
    }
}
