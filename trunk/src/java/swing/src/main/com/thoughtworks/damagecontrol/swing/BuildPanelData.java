package com.thoughtworks.damagecontrol.swing;

import com.thoughtworks.damagecontrol.buildmonitor.BuildConstants;
import com.thoughtworks.damagecontrol.buildmonitor.BuildPoller;
import com.thoughtworks.damagecontrol.buildmonitor.PollException;

import javax.swing.JButton;
import javax.swing.JPanel;
import javax.swing.JTable;
import javax.swing.JOptionPane;
import java.awt.Component;
import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.1 $
 */
public class BuildPanelData implements BuildConstants {
    private JPanel buildPanel;
    private JTable buildTable;
    private JButton refreshButton;

    public Component getPanel() {
        return buildPanel;
    }

    public BuildPanelData(final BuildPoller buildPoller) {
        TableModelBuildListener tableModelBuildListener = new TableModelBuildListener();
        buildTable.setModel(tableModelBuildListener.getTableModel());

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
    }
}