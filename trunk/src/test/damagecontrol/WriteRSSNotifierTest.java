package damagecontrol;

import damagecontrol.WriteRSSNotifier;
import damagecontrol.WriteToFileNotifier;
import damagecontrol.Builder;

public class WriteRSSNotifierTest extends WriteToFileNotifierTest {
    protected WriteToFileNotifier createNotifier(Builder builder) {
        return new WriteRSSNotifier(builder, tempFile.getAbsolutePath(), null, null);
    }
}
