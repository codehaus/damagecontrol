package damagecontrol;

import damagecontrol.WriteToFileNotifier;
import damagecontrol.Builder;

public class SimpleWriteToFileNotifierTest extends WriteToFileNotifierTest {
    protected WriteToFileNotifier createNotifier(Builder builder) {
        return new SimpleWriteToFileNotifier(builder, tempFile.getAbsolutePath());
    }
}
