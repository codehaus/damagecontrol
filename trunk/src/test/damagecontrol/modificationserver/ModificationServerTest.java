package damagecontrol.modificationserver;

import junit.framework.TestCase;

import java.io.IOException;
import java.lang.reflect.InvocationTargetException;
import java.util.Date;
import java.util.Calendar;

public class ModificationServerTest extends TestCase {

	private ModificationServer modificationServer;
	private EventReceiver mockEventReceiver;

	public void setUp() {
		mockEventReceiver = new MockEventReceiver();
		modificationServer = new ModificationServer(mockEventReceiver);
	}

	public void testSimpleNetworkReceive() throws IOException {
		modificationServer.start();
		Client c = new Client("127.0.0.1");
		c.sendLine("one");
		c.sendLine("two");
		c.close();

		assertEquals("one\r\ntwo\r\n", modificationServer.getLastRawMessage());
		modificationServer.stop();
	}

	public void testFakedReceive()
		throws NoSuchMethodException, ClassNotFoundException, InvocationTargetException, InstantiationException, IllegalAccessException {
		modificationServer.clientConnect();
		modificationServer.receiveLine("one");
		modificationServer.receiveLine("two");
		modificationServer.clientDisconnect();
		assertEquals("one\r\ntwo\r\n", modificationServer.getLastRawMessage());
	}

	public void testSimpleCVSReceive()
		throws NoSuchMethodException, ClassNotFoundException, InvocationTargetException, InstantiationException, IllegalAccessException {
		modificationServer.clientConnect();
		modificationServer.receiveLine("ModificationEvent");
		modificationServer.receiveLine("SourceControlType: CVS");
		modificationServer.receiveLine("RepositoryRoot: /home/cvsroot");
		modificationServer.receiveLine("EventDate: 20030617202000");
		modificationServer.receiveLine("User: mgm");
		modificationServer.clientDisconnect();

		assertNotNull(mockEventReceiver.getLastEvent());
	}

	public void testCVSReceive()
		throws NoSuchMethodException, ClassNotFoundException, InvocationTargetException, InstantiationException, IllegalAccessException {
		modificationServer.clientConnect();
		modificationServer.receiveLine("ModificationEvent");
		modificationServer.receiveLine("SourceControlType: CVS");
		modificationServer.receiveLine("RepositoryRoot: /home/cvsroot");
		modificationServer.receiveLine("EventDate: 20030617202000");
		modificationServer.receiveLine("User: mgm");
		modificationServer.receiveLine("FileAdded: src/added.java");
		modificationServer.receiveLine("FileModified: src/modified.java");
		modificationServer.receiveLine("FileDeleted: src/deleted.java");
		modificationServer.clientDisconnect();

		ModificationEvent receivedEvent = mockEventReceiver.getLastEvent();
		assertEquals("mgm", receivedEvent.getUser());
		assertEquals("/home/cvsroot", receivedEvent.getRepositoryRoot());
		Calendar expected = Calendar.getInstance();
		expected.set(2003, 05, 17, 20, 20, 00);
		expected.set(Calendar.MILLISECOND, 0);
		assertEquals(expected.getTime(), receivedEvent.getEventDate());
	}
}
