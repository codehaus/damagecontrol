package com.thoughtworks.damagecontrol.swing;

import com.thoughtworks.damagecontrol.buildmonitor.BuildConstants;
import com.thoughtworks.damagecontrol.buildmonitor.BuildPoller;
import com.thoughtworks.damagecontrol.buildmonitor.PollException;

import javax.swing.ComboBoxModel;
import javax.swing.DefaultCellEditor;
import javax.swing.DefaultComboBoxModel;
import javax.swing.DefaultListCellRenderer;
import javax.swing.JButton;
import javax.swing.JComboBox;
import javax.swing.JLabel;
import javax.swing.JList;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JTable;
import javax.swing.ListSelectionModel;
import javax.swing.event.ListSelectionEvent;
import javax.swing.event.ListSelectionListener;
import javax.swing.table.DefaultTableCellRenderer;
import javax.swing.table.DefaultTableModel;
import java.awt.Color;
import java.awt.Component;
import java.awt.Cursor;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.ItemEvent;
import java.awt.event.ItemListener;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.text.DateFormat;
import java.text.FieldPosition;
import java.text.SimpleDateFormat;
import java.util.Arrays;
import java.util.Date;
import java.util.List;
import java.util.Map;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.4 $
 */
public class BuildPanelData implements BuildConstants {
    private JPanel buildPanel;
    private JTable buildTable;
    private JButton refreshButton;
    private JLabel build_command_line;
    private JLabel timestamp;
    private JLabel status;
    private JLabel log;
    private static final long MINUTE = 1000 * 60;
    private static final long HOUR = 60 * MINUTE;
    private static final long DAY = 24 * HOUR;

    private static List periods = Arrays.asList(new Object[] {
        new Object[]{new Long(5*MINUTE), "About 5 minutes ago"},
        new Object[]{new Long(10*MINUTE), "About 10 minutes ago"},
        new Object[]{new Long(15*MINUTE), "About 15 minutes ago"},
        new Object[]{new Long(1*HOUR), "About an hour ago"},
        new Object[]{new Long(2*HOUR), "About two hours ago"},
        new Object[]{new Long(5*MINUTE), "Less than 5 minutes ago"},
        new Object[]{new Long(5*MINUTE), "Less than 5 minutes ago"},
    });

    public Component getPanel() {
        return buildPanel;
    }

    public BuildPanelData(final BuildPoller buildPoller) {
        TableModelBuildListener tableModelBuildListener = new TableModelBuildListener();
        final DefaultTableModel tableModel = tableModelBuildListener.getTableModel();
        buildTable.setModel(tableModel);

        refreshButton.addActionListener(new ActionListener(){
            public void actionPerformed(ActionEvent e) {
                try {
                    buildPoller.poll();
                } catch (PollException e1) {
                    JOptionPane.showMessageDialog(buildPanel, e1.getMessage(), "Polling failed!", JOptionPane.ERROR_MESSAGE);
                }
            }
        });

        buildPoller.addBuildListener(tableModelBuildListener);

        buildTable.setDefaultRenderer(List.class, new DefaultTableCellRenderer(){
            public Component getTableCellRendererComponent(JTable table, Object value, boolean isSelected, boolean hasFocus, int row, int column) {
                BuildSet buildSet = (BuildSet) value;
                Map build = (Map) buildSet.getSelected();
                String label = asText(build);
                JLabel result = (JLabel) super.getTableCellRendererComponent(table, label, isSelected, hasFocus, row, column);
                String status = (String) build.get(BuildConstants.STATUS_FIELD);
                    if(BuildConstants.STATUS_SUCCESSFUL.equals(status)) {
                        result.setBackground(Color.green);
                    } else if (BuildConstants.STATUS_FAILED.equals(status)) {
                        result.setBackground(Color.red);
                    } else if (BuildConstants.STATUS_IDLE.equals(status)) {
                        result.setBackground(Color.gray.brighter());
                    } else if (BuildConstants.STATUS_QUEUED.equals(status)) {
                        result.setBackground(Color.orange);
                    } else if (BuildConstants.STATUS_BUILDING.equals(status)) {
                        result.setBackground(Color.yellow);
                    } else if (BuildConstants.STATUS_CHECKING_OUT.equals(status)) {
                        result.setBackground(Color.yellow.brighter());
                    }
                return result;
            }
        });

        buildTable.setDefaultEditor(List.class, new BuildListCellEditor());

        buildTable.getSelectionModel().setSelectionMode(ListSelectionModel.SINGLE_INTERVAL_SELECTION);
        buildTable.getSelectionModel().addListSelectionListener(new ListSelectionListener(){
            public void valueChanged(ListSelectionEvent e) {
                int row = buildTable.getSelectedRow();
                BuildSet buildSet = (BuildSet) tableModel.getValueAt(row, 1);
                Map selectedBuild = buildSet.getSelected();
                updateDetails(selectedBuild);
            }
        });

        log.addMouseListener(new MouseAdapter(){
            public void mouseEntered(MouseEvent e) {
                e.getComponent().setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
            }

            public void mouseClicked(MouseEvent e) {
                String text = log.getText();
                int urlStart = text.indexOf("\"") + 1;
                int urlEnd = text.lastIndexOf("\"");
                String url = text.substring(urlStart, urlEnd);
                JOptionPane.showMessageDialog(e.getComponent(), "Not yet implemented: Show content at " + url);
            }
        });
    }

    private String asText(Map build) {
        final Date now = new Date();
        long timestamp = Long.parseLong((String) build.get(BuildConstants.TIMESTAMP_FIELD));
        final Date time = new Date(timestamp);
        String status = (String) build.get(BuildConstants.STATUS_FIELD);
        final long interval = now.getTime() - time.getTime();
        DateFormat dateFormat = new SimpleDateFormat() /*{
            public StringBuffer format(Date date, StringBuffer toAppendTo, FieldPosition pos) {
                if(interval < 5 * MINUTE) {
                    return toAppendTo.append("Less than 5 minutes ago");
                }
                if(interval < 15 * MINUTE) {
                    return toAppendTo.append("Less than 15 minutes ago");
                }
                if(interval < HOUR) {
                    return toAppendTo.append("Less than one hour ago");
                }
                if(interval < 15 * MINUTE) {
                    return toAppendTo.append("Less than 15 minutes ago");
                }
                return super.format(date, toAppendTo, pos);
            }
        }*/;
        return status + " (" + dateFormat.format(time) + ")";
    }

    private void updateDetails(Map build) {
        timestamp.setText((String) build.get(BuildConstants.TIMESTAMP_FIELD));
        String status = build.get(BuildConstants.STATUS_FIELD).toString();
        this.status.setText(status);

        Map config = (Map) build.get(BuildConstants.CONFIG_FIELD);
        String cmdline = config == null ? null : (String) config.get("build_command_line");
        build_command_line.setText(cmdline);

        this.status.repaint();
    }

    private class BuildListCellEditor extends DefaultCellEditor {
        private BuildSet buildSet;

        public BuildListCellEditor() {
            super(new JComboBox());
            JComboBox comboBox = (JComboBox) getComponent();
            comboBox.setRenderer(new DefaultListCellRenderer(){
                public Component getListCellRendererComponent(JList list, Object value, int index, boolean isSelected, boolean cellHasFocus) {
                    JLabel result = (JLabel) super.getListCellRendererComponent(list, value, index, isSelected, cellHasFocus);
                    Map build = (Map) value;
                    String label = asText(build);
                    result.setText(label);
                    return result;
                }
            });
        }

        public Component getTableCellEditorComponent(JTable table, Object value, boolean isSelected, int row, int column) {
            final JComboBox result = (JComboBox) super.getTableCellEditorComponent(table, value, isSelected, row, column);
            buildSet = (BuildSet) value;
            List builds = buildSet.getBuilds();
            final Map selected = buildSet.getSelected();
            ComboBoxModel model = new DefaultComboBoxModel(builds.toArray());
            model.setSelectedItem(selected);
            result.addItemListener(new ItemListener(){
                public void itemStateChanged(ItemEvent e) {
                    if (e.getStateChange() == ItemEvent.SELECTED) {
                        Map build = (Map) e.getItem();
                        buildSet.setSelected(build);
                        updateDetails(build);
                    }
                }
            });
            result.setModel(model);
            return result;
        }

        public Object getCellEditorValue() {
            return buildSet;
        }
    }
}