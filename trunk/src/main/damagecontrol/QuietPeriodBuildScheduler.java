package damagecontrol;

/**
 * This build scheduler will defer the invocation of a builder until
 * a quiet period. A quiet period means that no build requests have been
 * received within a certain period.
 *
 * Commits to an SCM are frequently done in several operations, and
 * a build for a particular project should probably not be called until
 * that project has been quiet for a while.
 *
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.1 $
 */
public class QuietPeriodBuildScheduler implements BuildScheduler {
    /**
     * Sync lock used to keep waiting until quiet period is fulfilled.
     */
    private final Object lock = new Object();
    private final Builder builder;
    private final long quietPerionMillis;

    private boolean isBuildRunning;

    private Thread buildThread;

    public QuietPeriodBuildScheduler(int quietPerionMillis, Builder builder) {
        this.quietPerionMillis = quietPerionMillis;
        this.builder = builder;
    }

    public void requestBuild() {
        // Interrupt the builder thread that's waiting
        synchronized(lock) {
            System.out.println("Interrupting (potentially)");
            //lock.notify();
            if (buildThread != null) {
                buildThread.interrupt();
            }
            System.out.println("Interrupted (potentially)");
        }

        // Spawn a new Thread
        buildThread = new Thread(new Runnable(){
            public void run() {
                // wait for a while.
                synchronized(lock) {
                    try {
                        System.out.println("I'm waiting for a quiet period...");
                        lock.wait(quietPerionMillis);
                        System.out.println("That's quiet enuough. Launching build...");
                        isBuildRunning = true;
                        builder.build();
                    } catch (InterruptedException e) {
                        System.out.println("I was interrupted when waiting for a quiet period");
                    } finally {
                        isBuildRunning = false;
                    }
                }
            }
        });

        buildThread.start();

    }

    public boolean isBuildRunning() {
        return isBuildRunning;
    }
}
