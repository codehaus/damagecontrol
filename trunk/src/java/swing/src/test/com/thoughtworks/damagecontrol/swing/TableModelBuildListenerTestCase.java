package com.thoughtworks.damagecontrol.swing;

import com.thoughtworks.damagecontrol.buildmonitor.BuildConstants;
import junit.framework.TestCase;

import javax.swing.table.DefaultTableModel;
import java.lang.reflect.InvocationTargetException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Vector;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.4 $
 */
public class TableModelBuildListenerTestCase extends TestCase {
    public void testStatusIsReportedForBuildStarted() throws InvocationTargetException, InterruptedException {

        List appleList = new ArrayList();
        Map apple1 = new HashMap();
        apple1.put(BuildConstants.PROJECT_NAME_FIELD, "apple");
        apple1.put(BuildConstants.STATUS_FIELD, Boolean.TRUE);
        appleList.add(apple1);

        Map apple2 = new HashMap();
        apple2.put(BuildConstants.PROJECT_NAME_FIELD, "apple");
        apple2.put(BuildConstants.STATUS_FIELD, Boolean.FALSE);
        appleList.add(apple2);

        List pearList = new ArrayList();
        Map pear1 = new HashMap();
        pear1.put(BuildConstants.PROJECT_NAME_FIELD, "pear");
        pear1.put(BuildConstants.STATUS_FIELD, Boolean.TRUE);
        pearList.add(pear1);

        TableModelBuildListener buildListener = new TableModelBuildListener();
        final DefaultTableModel tableModel = buildListener.getTableModel();

        final Map buildListMap = new HashMap();
        buildListMap.put("apple", appleList);
        buildListMap.put("pear", pearList);

        buildListener.update(buildListMap);

        final Vector expectedVector = new Vector();
        Vector appleRow = new Vector();
        Vector pearRow = new Vector();
        appleRow.add("apple");
        appleRow.add(new BuildSet(appleList));
        pearRow.add("pear");
        pearRow.add(new BuildSet(pearList));
        expectedVector.add(pearRow);
        expectedVector.add(appleRow);

        // Allow the swing thread to do its job
        Thread.sleep(1000);
        Vector dataVector = tableModel.getDataVector();

        assertEquals(expectedVector, dataVector);
    }
}