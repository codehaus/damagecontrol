package damagecontrol;

/**
 * 
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.2 $
 */
public interface Clock {
    void waitUntil(long timeInMillis) throws InterruptedException;
    long currentTimeMillis();
}
