package damagecontrol.modificationserver;

import java.net.Socket;
import java.net.UnknownHostException;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;

public class Client {
	private final PrintWriter writer;

	public Client(String serverAddress) throws IOException, UnknownHostException {
		Socket socket = new Socket(serverAddress, ModificationServer.DEFAULT_PORT);
		OutputStreamWriter osw = new OutputStreamWriter(socket.getOutputStream(),
														ModificationServer.NETWORK_CHARSET);
		writer = new PrintWriter(osw);
	}

	public void sendLine(String line) throws IOException {
		writer.println(line);
	}

	public void close() throws IOException {
		writer.close();
	}
}
