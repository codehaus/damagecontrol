package org.rubyforge.rscm;

import java.io.Writer;
import java.io.IOException;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision$
 */
public interface YamlDumpable {
    void dumpYaml(Writer out) throws IOException;
}
