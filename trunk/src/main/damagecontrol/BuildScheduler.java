package damagecontrol;

/**
 * A build scheduler is responsible for invoking a build.
 * It's up to the concrete build schedulers to implement the
 * strategy for when/how to invoke a build.
 *
 * @author Aslak Helles&oslash;y
 * @author Jon Tirs&eacute;n
 * @version $Revision: 1.2 $
 */
public interface BuildScheduler {
    /**
     * Requests a build.
     * @param builder the builder that will perform the build.
     */
    void requestBuild(Builder builder);

    /**
     * Returns the currently running Builder. If no builder is
     * currently running, null is returned.
     * @return currently running Builder.
     */
    Builder getCurrentlyRunningBuilder();
}
