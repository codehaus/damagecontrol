package damagecontrol;

/**
 * 
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.1 $
 */
public class DirectSchedulerTest extends AbstractSchedulerTest {
    protected Scheduler createScheduler() {
        return new DirectScheduler();
    }
}
