package damagecontrol.event;

import damagecontrol.modificationserver.ModificationEvent;

import java.util.Date;
import java.util.Set;
import java.util.HashSet;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.text.ParseException;

public class CVSModificationEvent implements ModificationEvent {

	private String repositoryRoot;
	private String user;
	private Date eventDate;
	private Set filesAdded = new HashSet();
	private Set filesModified = new HashSet();
	private Set filesDeleted = new HashSet();

	public CVSModificationEvent() {
	}

	public String getRepositoryRoot() {
		return repositoryRoot;
	}

	public void setRepositoryRoot(String repositoryRoot) {
		this.repositoryRoot = repositoryRoot;
	}

	public String getUser() {
		return user;
	}

	public void setUser(String user) {
		this.user = user;
	}

	public Date getEventDate() {
		return eventDate;
	}

	public void setEventDate(String eventAsString) throws ParseException {
		DateFormat format = new SimpleDateFormat("yyyyMMddHHmmss");
		this.eventDate = format.parse(eventAsString);
	}

	public void setFileAdded(String file) {
		filesAdded.add(file);
	}

	public void setFileModified(String file) {
		filesModified.add(file);
	}

	public void setFileDeleted(String file) {
		filesDeleted.add(file);
	}
}
