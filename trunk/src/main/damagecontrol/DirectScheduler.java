package damagecontrol;

import java.util.Map;
import java.util.HashMap;

/**
 * A simple scheduler that will invoke a builder immediately
 * as it's being requested. This scheduler is not recommended for
 * production use, as it will block during the delay of the build.
 * It is recommended to use a builder that will launch builds
 * in a separate thread, like {@link QuietPeriodScheduler).
 * TODO: write a DirectAsynchronousScheduler that launches at once
 * like this one, but in a separate thread. That can be used with
 * SCMs supporting attomic commits (like subversion).
 *
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.1 $
 */
public class DirectScheduler extends AbstractScheduler {

    public void requestBuild(String builderName) throws NoSuchBuilderException {
        getBuilder(builderName).build();
    }

}
