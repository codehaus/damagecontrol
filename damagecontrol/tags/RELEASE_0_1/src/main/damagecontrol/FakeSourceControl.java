package damagecontrol;

import net.sourceforge.cruisecontrol.SourceControl;
import net.sourceforge.cruisecontrol.Modification;
import net.sourceforge.cruisecontrol.CruiseControlException;

import java.util.List;
import java.util.Date;
import java.util.ArrayList;
import java.util.Hashtable;

public class FakeSourceControl implements SourceControl {
    private String type;

    public void setType(String type) {
        this.type = type;
    }

    public List getModifications(Date lastbuild, Date now) {
        List modifications = new ArrayList();
        Modification modification = new Modification();
        modification.type = type;
        modification.modifiedTime = now;
        modification.revision = "revision";
        modification.comment = "comment";
        modification.emailAddress = "emailAddress";
        modification.fileName = "fileName";
        modification.folderName = "folderName";
        modifications.add(modification);
        return modifications;
    }

    public void validate() throws CruiseControlException {
    }

    public Hashtable getProperties() {
        return null;
    }

    public void setProperty(String s) {
    }

    public void setPropertyOnDelete(String s) {
    }
}
