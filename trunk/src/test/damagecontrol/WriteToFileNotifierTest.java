package damagecontrol.listeners;

import junit.framework.TestCase;

import java.io.File;
import java.io.FileReader;
import java.io.IOException;

import damagecontrol.listeners.WriteToFileNotifier;
import damagecontrol.MockBuilder;
import damagecontrol.Builder;

public abstract class WriteToFileNotifierTest extends TestCase {
    protected File tempFile;

    protected void setUp() throws Exception {
        super.setUp();
        tempFile = File.createTempFile("damagecontrol", ".tmp");
        tempFile.delete();
        System.out.println(tempFile.toURL());
    }

    protected void tearDown() throws Exception {
        tempFile.delete();
        super.tearDown();
    }

    public void testNotifierWritesBuildOutputToFile() throws IOException {
        MockBuilder builder = new MockBuilder("Output");
        WriteToFileNotifier notifier = createNotifier(builder);
        assertTrue(builder.buildListeners.contains(notifier));

        assertFalse(tempFile.exists());
        builder.build();
        assertTrue(tempFile.isFile());
        assertEquals("Output", toString(tempFile));
    }

    protected abstract WriteToFileNotifier createNotifier(Builder builder);

    private String toString(File file) throws IOException {
        StringBuffer buffer = new StringBuffer();
        FileReader reader = new FileReader(file);
        int read;
        while ((read = reader.read()) != -1) {
            buffer.append((char) read);
        }
        return buffer.toString();
    }
}
