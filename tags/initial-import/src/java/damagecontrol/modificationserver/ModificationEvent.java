package damagecontrol.modificationserver;

import java.util.Date;

public interface ModificationEvent {

	String getUser();
	String getRepositoryRoot();
	Date getEventDate();

}
