package damagecontrol.modificationserver;

public class MockEventReceiver implements EventReceiver {

	private ModificationEvent lastEvent;

	public MockEventReceiver() {
	}

	public void receiveEvent(ModificationEvent event) {
		lastEvent = event;
	}

	public ModificationEvent getLastEvent() {
		return lastEvent;
	}
}
