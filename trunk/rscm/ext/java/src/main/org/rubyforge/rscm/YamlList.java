package org.rubyforge.rscm;

import java.util.ArrayList;
import java.util.Iterator;
import java.io.Writer;
import java.io.IOException;

/**
 * Simple yamlable list.
 *
 * @author Aslak Helles&oslash;y
 * @version $Revision$
 */
public class YamlList extends ArrayList implements YamlDumpable {

    public void dumpYaml(Writer out) throws IOException {
        out.write("--- ");
        if(!isEmpty()) {
            out.write("\n");
            for (Iterator iterator = this.iterator(); iterator.hasNext();) {
                String s = (String) iterator.next();
                out.write("- ");
                out.write(s);
                out.write("\n");
            }
        } else {
            out.write("[]");
        }
    }
}
