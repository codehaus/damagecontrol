package org.rubyforge.rscm;

import java.io.IOException;
import java.io.Writer;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

/**
 * @author Aslak Helles&oslash;y
 */
public class ChangeSets implements YamlDumpable {
    private List changeSets = new ArrayList();

    public void add(ChangeSet changeSet) {
        changeSets.add(changeSet);
    }

    public void dumpYaml(Writer out) throws IOException {
        out.write("--- !ruby/object:RSCM::ChangeSets \n");
        out.write("changesets: \n");
        for (Iterator iterator = changeSets.iterator(); iterator.hasNext();) {
            ChangeSet changeSet = (ChangeSet) iterator.next();
            changeSet.write(out);
        }
    }

    public void add(Change change) {
        ChangeSet changeSetForChange = getChangeSetForChange(change);
        if(changeSetForChange == null) {
            changeSetForChange = new ChangeSet(change);
            changeSets.add(changeSetForChange);
        }
        changeSetForChange.add(change);
    }

    private ChangeSet getChangeSetForChange(Change change) {
        for (Iterator iterator = changeSets.iterator(); iterator.hasNext();) {
            ChangeSet changeSet = (ChangeSet) iterator.next();
            if(changeSet.canContain(change)) {
                return changeSet;
            }
        }
        return null;
    }
}
