package damagecontrol;

import java.io.*;

public class ExecBuilder extends AbstractBuilder {
    private String command;

    public ExecBuilder(String name, Scheduler scheduler, String command) {
        super(name, scheduler);
        this.command = command;
    }

    public boolean doBuild(StringBuffer output) {
        try {
            Process process = Runtime.getRuntime().exec(command);
            InputStream inputStream = process.getInputStream();
            Reader reader = new InputStreamReader(inputStream);
            int c;
            while ((c = reader.read()) != -1) {
                output.append((char) c);
            }
        } catch (IOException e) {
            output.append("ERROR: " + e.getMessage());
            return false;
        }
        return true;
    }
}
