package damagecontrol;

/**
 * 
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.1 $
 */
public interface Clock {
    void waitUntil(long timeInMillis);
    long currentTimeMillis();
}
