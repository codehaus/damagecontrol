package damagecontrol.testtest;

import damagecontrol.testtest.SimpleWriteToFileNotifier;
import damagecontrol.listeners.WriteToFileNotifierTest;
import damagecontrol.listeners.WriteToFileNotifier;
import damagecontrol.Builder;

public class SimpleWriteToFileNotifierTest extends WriteToFileNotifierTest {
    protected WriteToFileNotifier createNotifier(Builder builder) {
        return new SimpleWriteToFileNotifier(builder, tempFile.getAbsolutePath());
    }
}
