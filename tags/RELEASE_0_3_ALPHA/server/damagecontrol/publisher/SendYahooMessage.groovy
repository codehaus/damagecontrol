public class SendYahooMessage
{
	static usage() {
		println("SendYahooMessage <username> <password> <user to send to> <message>")
		System.exit(1);
	}

	public static void main(String[] args) {
		username = args[0]
		password = args[1]
		recipient = args[2]
		message = args[3]
		
		s = new ymsg.network.Session(new ymsg.network.DirectConnectionHandler())
		s.login(username, password)
		s.sendMessage(recipient, message)
		Thread.sleep(500)
		s.logout()
		s.reset()
	}
}
