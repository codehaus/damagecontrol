package org.rubyforge.rscm;

import java.util.List;

/**
 * Java implementation of part of the RSCM API.
 *
 * @author Aslak Helles&oslash;y
 */
public interface RSCM {
    YamlDumpable getChangeSets(String fromIdentifier, String toIdentifier);

    /**
     * @param dir where to check out
     * @param toIdentifier date (java.util.Date) or label (java.lang.String)
     * @return
     */
    YamlDumpable checkout(String dir, String toIdentifier);
}
