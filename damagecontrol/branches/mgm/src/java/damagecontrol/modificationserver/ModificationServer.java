package damagecontrol.modificationserver;

import org.apache.log4j.Logger;

import java.net.Socket;
import java.net.ServerSocket;
import java.net.SocketTimeoutException;
import java.io.IOException;
import java.io.InputStreamReader;
import java.lang.reflect.InvocationTargetException;

import damagecontrol.util.Logging;

public class ModificationServer implements Runnable {

	public static final int DEFAULT_PORT = 3642;
	public static final String NETWORK_CHARSET = "UTF8";
	private static final int SO_TIMEOUT = 500;

	private static final Logger log = Logging.getLogger(ModificationServer.class);
	private ServerSocket listenSocket;
	private StringBuffer currentMessage;
	private boolean keepListening;
	private final EventReceiver eventReceiver;

	public ModificationServer(EventReceiver eventReceiver) {
		currentMessage = new StringBuffer();
		this.eventReceiver = eventReceiver;
	}

	public void start() throws IOException {
		keepListening = true;
		listenSocket = new ServerSocket(DEFAULT_PORT);
		listenSocket.setSoTimeout(SO_TIMEOUT);
		Thread serverThread = new Thread(this);
		serverThread.start();
	}

	public void stop() {
		keepListening = false;
		pause(SO_TIMEOUT);
	}

	private void pause(long howLong) {
		try {
			Thread.sleep(howLong);
		} catch(InterruptedException ignored) {
			// Do nothing
		}
	}

	public String getLastRawMessage() {
		return currentMessage.toString();
	}

	public void run() {
		while(keepListening) {
			try {
				Socket s = listenSocket.accept();
				handleIncomingConnection(s);
			} catch(SocketTimeoutException ignored) {
				// Do nothing, we're just waiting for the next client
			} catch (IOException e) {
				log.error("Caught IO Exception whilst listening", e);
				break;
			} catch (NoSuchMethodException e) {
				e.printStackTrace();  //To change body of catch statement use Options | File Templates.
			} catch (ClassNotFoundException e) {
				e.printStackTrace();  //To change body of catch statement use Options | File Templates.
			} catch (InvocationTargetException e) {
				e.printStackTrace();  //To change body of catch statement use Options | File Templates.
			} catch (InstantiationException e) {
				e.printStackTrace();  //To change body of catch statement use Options | File Templates.
			} catch (IllegalAccessException e) {
				e.printStackTrace();  //To change body of catch statement use Options | File Templates.
			}
		}
		log.debug("Stopped listening");
	}

	private void handleIncomingConnection(Socket socket) throws IOException, NoSuchMethodException, ClassNotFoundException, InvocationTargetException, InstantiationException, IllegalAccessException {
		// TODO: Spawn a thread so we can handle concurrent clients (or misbehaving ones)
		currentMessage = new StringBuffer();
		InputStreamReader isr = new InputStreamReader(socket.getInputStream(), NETWORK_CHARSET);
		int c;
		while((c = isr.read()) != -1) {
			currentMessage.append((char) c);
		}
		clientDisconnect();
	}

	void receiveLine(String line) {
		currentMessage.append(line + "\r\n");
	}

	void clientConnect() {
		currentMessage = new StringBuffer();
	}

	void clientDisconnect() throws NoSuchMethodException, ClassNotFoundException, InvocationTargetException, InstantiationException, IllegalAccessException {
		parseCurrentMessage();
	}

	private void parseCurrentMessage() throws NoSuchMethodException, ClassNotFoundException, InvocationTargetException, InstantiationException, IllegalAccessException {
		eventReceiver.receiveEvent(ModificationEventFactory.parseModificationEvent(currentMessage.toString()));
	}
}
