package damagecontrol;

/**
 * A build scheduler is responsible for invoking a build.
 * It's up to the concrete build schedulers to implement the
 * strategy for when/how to invoke a build.
 *
 * @author Aslak Helles&oslash;y
 * @author Jon Tirs&eacute;n
 * @version $Revision: 1.1 $
 */
public interface Scheduler {
    /**
     * Requests a build.
     */
    void requestBuild(String builderName) throws NoSuchBuilderException;

    void registerBuilder(String builderName, Builder builder);
}
