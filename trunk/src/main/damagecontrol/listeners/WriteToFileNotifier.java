package damagecontrol.listeners;

import damagecontrol.BuildListener;
import damagecontrol.Builder;
import damagecontrol.BuildEvent;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;

public abstract class WriteToFileNotifier implements BuildListener {
    private File fileToWriteTo;

    public WriteToFileNotifier(Builder builder, String fileToWriteTo) {
        builder.addBuildListener(this);
        this.fileToWriteTo = new File(fileToWriteTo);
    }

    public void buildFinished(BuildEvent evt) {
        try {
            FileWriter writer = new FileWriter(fileToWriteTo);
            try {
                writeOutput(writer, evt);
            } finally {
                writer.close();
            }
        } catch (IOException e) {
            e.printStackTrace();
            throw new RuntimeException();
        }
    }

    protected abstract void writeOutput(FileWriter writer, BuildEvent evt) throws IOException;
}
