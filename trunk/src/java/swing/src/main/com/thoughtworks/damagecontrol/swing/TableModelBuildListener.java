package com.thoughtworks.damagecontrol.swing;

import com.thoughtworks.damagecontrol.buildmonitor.BuildListener;
import com.thoughtworks.damagecontrol.buildmonitor.BuildConstants;

import javax.swing.table.DefaultTableModel;
import javax.swing.SwingUtilities;
import java.util.List;
import java.util.Iterator;
import java.util.Map;

/**
 * This BuildListener updates a {@link DefaultTableModel} upon events.
 * The updating of the table model will happen in the swing thread.
 *
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.1 $
 */
public class TableModelBuildListener implements BuildListener, BuildConstants {
    private static final Object[] COLUMNS = new String[]{NAME_FIELD, STATUS_FIELD};
    private final DefaultTableModel tableModel = new DefaultTableModel(COLUMNS, 0);

    public void update(List buildList) {
        final Object[][] data = new Object[buildList.size()][2];
        int row = 0;
        for (Iterator iterator = buildList.iterator(); iterator.hasNext();) {
            Map buildMap = (Map) iterator.next();
            data[row] = new Object[] {
                buildMap.get(NAME_FIELD),
                buildMap.get(STATUS_FIELD)
            };
            row++;
        }
        SwingUtilities.invokeLater(new Runnable(){
            public void run() {
                tableModel.setDataVector(data, COLUMNS);
            }
        });
    }

    public DefaultTableModel getTableModel() {
        return tableModel;
    }
}