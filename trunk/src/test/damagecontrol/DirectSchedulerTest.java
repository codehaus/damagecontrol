package damagecontrol;

/**
 * 
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.2 $
 */
public class DirectSchedulerTest extends AbstractSchedulerTest {
    protected Scheduler getScheduler() {
        return new DirectScheduler();
    }
}
