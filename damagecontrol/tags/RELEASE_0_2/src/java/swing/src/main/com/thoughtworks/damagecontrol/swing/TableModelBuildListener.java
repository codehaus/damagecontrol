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
 * @version $Revision: 1.2 $
 */
public class TableModelBuildListener implements BuildListener, BuildConstants {
    private static final Object[] COLUMNS = new String[]{PROJECT_NAME_FIELD, "status"};
    private static final Class[] COLUMN_CLASSES = new Class[]{String.class, List.class};
    private final DefaultTableModel tableModel = new DefaultTableModel(COLUMNS, 0) {
        public Class getColumnClass(int columnIndex) {
            return COLUMN_CLASSES[columnIndex];
        }

        public void setValueAt(Object aValue, int row, int column) {
            super.setValueAt(aValue, row, column);
        }
    };

    public void update(Map buildListMap) {
        final Object[][] data = new Object[buildListMap.size()][2];
        int row = 0;
        for (Iterator iterator = buildListMap.keySet().iterator(); iterator.hasNext();) {
            String projectName = (String) iterator.next();
            List buildList = (List) buildListMap.get(projectName);
            BuildSet buildSet = new BuildSet(buildList);
            data[row] = new Object[] {
                projectName,
                buildSet
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