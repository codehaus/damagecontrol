package org.rubyforge.rscm;

import java.util.Date;

/**
 * Java implementation of part of the RSCM API.
 *
 * @author Aslak Helles&oslash;y
 */
public interface RSCM {
    // TODO: move folderName to starteam's ctor, it's a bit weird here - may not fit with other scms.
    ChangeSets getChangeSets(Date from, Date to, String folderName);
}
