package org.rubyforge.rscm;

import java.io.IOException;
import java.io.Writer;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Collections;

/**
 * @author Aslak Helles&oslash;y
 */
public class ChangeSet implements Comparable {
    private List changes = new ArrayList();
    private Change myChange;

    public ChangeSet(Change change) {
        this.myChange = change;
    }

    public void add(Change change) {
        changes.add(change);
        if(change.getTime().getTime() > myChange.getTime().getTime()) {
            myChange = change;
        }
    }

    public void write(Writer out) throws IOException {
        Collections.sort(changes);
        out.write("  - !ruby/object:RSCM::ChangeSet \n");
        out.write("    changes: \n");
        for (Iterator iterator = changes.iterator(); iterator.hasNext();) {
            Change change = (Change) iterator.next();
            change.write(out);
        }
        out.write("    developer: ");
        out.write(myChange.getDeveloper());
        out.write("\n");
        out.write("    time: ");
        out.write(Change.format(myChange.getTime()));
        out.write(" Z\n");
        out.write("    message: \"");
        Change.yamlIndent(myChange.getMessage(), "      ", out);
        out.write("\"\n");
    }

    public boolean canContain(Change change) {
        return myChange.isSimilarWithinOneMinute(change);
    }

    public int compareTo(Object o) {
        ChangeSet other = (ChangeSet) o;
        // sort in rev. order.
        return - myChange.getTime().compareTo(other.myChange.getTime());
    }
}
