package damagecontrol;

/**
 * This interface is an abstraction of a build tool.
 * There will typically be concrete implementations
 * for various tools like Ant, Maven, Make, pure exec etc.
 *
 * It is usually associated with a {@link BuildScheduler}
 * that is responsible for invoking the actual build.
 * 
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.1 $
 */
public interface Builder {
    /**
     * Invokes the build. This method will typically block for the
     * whole duration of the build.
     */
    void build();

    /**
     * Returns the build number. This value should be incremented
     * for each successful invocation of {@link #build}. It should not
     * be invoked for an unsuccessful build.
     * @return the build number.
     */
    int getBuildNumber();
}
