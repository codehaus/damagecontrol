package damagecontrol;

import junit.framework.TestCase;
import net.sourceforge.cruisecontrol.Modification;

import java.util.Date;

public class CruiseControlBridgeTest extends TestCase {
    public void test() throws Exception {
        CruiseControlBridge bridge = new CruiseControlBridge();
        Date lastbuild = new Date();
        Date now = new Date();
        bridge.init(new String[] { "damagecontrol.FakeSourceControl",
                                   "-type", "type",
                                   "-lastbuild", CruiseControlBridge.DATE_FORMAT.format(lastbuild),
                                   "-now", CruiseControlBridge.DATE_FORMAT.format(now) });
        assertDateEquals(lastbuild, bridge.lastbuild);
        assertDateEquals(now, bridge.now);
        assertTrue(bridge.sourceControl instanceof FakeSourceControl);
        FakeSourceControl sourceControl = (FakeSourceControl) bridge.sourceControl;
        Modification modification = (Modification) sourceControl.getModifications(bridge.lastbuild, bridge.now).get(0);
        assertEquals("type", modification.type);
        assertEquals(bridge.now, modification.modifiedTime);
    }

    private void assertDateEquals(Date expected, Date actual) {
        assertEquals(CruiseControlBridge.DATE_FORMAT.format(expected), CruiseControlBridge.DATE_FORMAT.format(actual));
    }

}
