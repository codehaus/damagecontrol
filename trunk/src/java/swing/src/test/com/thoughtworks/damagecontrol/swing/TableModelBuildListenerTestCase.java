package com.thoughtworks.damagecontrol.swing;

import com.thoughtworks.damagecontrol.buildmonitor.BuildConstants;
import com.thoughtworks.damagecontrol.buildmonitor.BuildListener;
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
 * @version $Revision: 1.1 $
 */
public class TableModelBuildListenerTestCase extends TestCase {
    public void testStatusIsReportedForBuildStarted() throws InvocationTargetException, InterruptedException {

        List buildList = new ArrayList();

        Map three = new HashMap();
        three.put(BuildConstants.NAME_FIELD, "three");
        three.put(BuildConstants.STATUS_FIELD, BuildConstants.STATUS_FAILED);
        buildList.add(three);

        Map blind = new HashMap();
        blind.put(BuildConstants.NAME_FIELD, "blind");
        blind.put(BuildConstants.STATUS_FIELD, BuildConstants.STATUS_SUCCESSFUL);
        buildList.add(blind);

        Map mice = new HashMap();
        mice.put(BuildConstants.NAME_FIELD, "mice");
        mice.put(BuildConstants.STATUS_FIELD, BuildConstants.STATUS_QUEUED);
        buildList.add(mice);

        TableModelBuildListener buildListener = new TableModelBuildListener();
        final DefaultTableModel tableModel = buildListener.getTableModel();
        buildListener.update(buildList);

        final Vector expectedVector = new Vector();

        Vector rowOne = new Vector();
        rowOne.add("three");
        rowOne.add(BuildConstants.STATUS_FAILED);
        expectedVector.add(rowOne);

        Vector rowTwo = new Vector();
        rowTwo.add("blind");
        rowTwo.add(BuildConstants.STATUS_SUCCESSFUL);
        expectedVector.add(rowTwo);

        Vector rowThree = new Vector();
        rowThree.add("mice");
        rowThree.add(BuildConstants.STATUS_QUEUED);
        expectedVector.add(rowThree);

        SwingUtilities.invokeAndWait(new Runnable() {
            public void run() {
                assertEquals(expectedVector, tableModel.getDataVector());
            }
        });
    }
}