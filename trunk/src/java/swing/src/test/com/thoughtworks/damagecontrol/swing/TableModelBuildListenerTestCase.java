package com.thoughtworks.damagecontrol.swing;

import com.thoughtworks.damagecontrol.buildmonitor.BuildConstants;
import junit.framework.TestCase;

import javax.swing.SwingUtilities;
import javax.swing.table.DefaultTableModel;
import java.lang.reflect.InvocationTargetException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Vector;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.2 $
 */
public class TableModelBuildListenerTestCase extends TestCase {
    public void testStatusIsReportedForBuildStarted() throws InvocationTargetException, InterruptedException {

        List appleList = new ArrayList();
        Map three = new HashMap();
        three.put(BuildConstants.PROJECT_NAME_FIELD, "apple");
        three.put(BuildConstants.SUCCESSFUL_FIELD, Boolean.TRUE);
        appleList.add(three);

        Map mice = new HashMap();
        mice.put(BuildConstants.PROJECT_NAME_FIELD, "apple");
        mice.put(BuildConstants.SUCCESSFUL_FIELD, Boolean.FALSE);
        appleList.add(mice);

        List pearList = new ArrayList();
        Map blind = new HashMap();
        blind.put(BuildConstants.PROJECT_NAME_FIELD, "pear");
        blind.put(BuildConstants.SUCCESSFUL_FIELD, Boolean.TRUE);
        pearList.add(blind);

        TableModelBuildListener buildListener = new TableModelBuildListener();
        final DefaultTableModel tableModel = buildListener.getTableModel();

        Map buildListMap = new HashMap();
        buildListMap.put("apple", appleList);
        buildListMap.put("pear", pearList);

        buildListener.update(buildListMap);

        final Vector expectedVector = new Vector();

        Vector rowOne = new Vector();
        rowOne.add("apple");
        rowOne.add(Boolean.TRUE);
        expectedVector.add(rowOne);

        Vector rowTwo = new Vector();
        rowTwo.add("pear");
        rowTwo.add(Boolean.TRUE);
        expectedVector.add(rowTwo);

        Vector rowThree = new Vector();
        rowThree.add("apple");
        rowThree.add(Boolean.TRUE);
        expectedVector.add(rowThree);

        SwingUtilities.invokeAndWait(new Runnable() {
            public void run() {
                assertEquals(expectedVector, tableModel.getDataVector());
            }
        });
    }
}