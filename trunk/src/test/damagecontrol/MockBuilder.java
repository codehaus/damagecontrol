package damagecontrol;

/**
 * 
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.2 $
 */
public class MockBuilder implements Builder {
    private long buildDurationMillis;
    private int buildCount;
    private String name;

    public MockBuilder(String name, long buildDurationMillis) {
        this.name = name;
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

    public String getName() {
        return name;
    }

    public String toString() {
        return getName();
    }
}
