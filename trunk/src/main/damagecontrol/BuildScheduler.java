package damagecontrol;

/**
 * A build scheduler is responsible for invoking a build.
 * It's up to the concrete build schedulers to implement the
 * strategy for when/how to invoke a build.
 *
 * TODO: one BuildScheduler per Builder or one per machine?
 * We want to make sure that builds for several projects
 * aren't run simultaneously.
 *
 * @author Aslak Helles&oslash;y
 * @author Jon Tirs&eacute;n
 * @version $Revision: 1.1 $
 */
public interface BuildScheduler {
    // TODO take a Builder as arg?
    void requestBuild();

    // TODO move to Builder? It's nice to avoid threading in Builder impls.
    // If we move this method to Builder, we have blocking issues. Better keep it
    // here. Maybe take Builder as arg here too.
    boolean isBuildRunning();
}
