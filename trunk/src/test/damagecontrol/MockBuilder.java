package damagecontrol;

/**
 * 
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.1 $
 */
public class MockBuilder implements Builder {
    private long buildDurationMillis;
    private int buildCount;

    public MockBuilder(long buildDurationMillis) {
        this.buildDurationMillis = buildDurationMillis;
    }

    public void build() {
        try {
            Thread.sleep(buildDurationMillis);
            buildCount++;
        } catch (InterruptedException e) {
            System.out.println("WTF!!!");
        }
    }

    public int getBuildNumber() {
        return buildCount;
    }

}
