package damagecontrol.modificationserver;

public interface EventReceiver {

	void receiveEvent(ModificationEvent event);

	ModificationEvent getLastEvent();
}
