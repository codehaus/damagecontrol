package com.thoughtworks.damagecontrol.swing;

import com.thoughtworks.damagecontrol.buildmonitor.BuildConstants;
import com.thoughtworks.damagecontrol.buildmonitor.BuildListener;
import com.thoughtworks.damagecontrol.buildmonitor.BuildPoller;

import javax.swing.JFrame;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.1 $
 */
public class BuildPanelDemo {
    private static BuildListener bl;
    private static int i;

    public static void main(String[] args) {
        BuildPanelData buildPanel = new BuildPanelData(new BuildPoller(){
            public void addBuildListener(BuildListener buildListener) {
                bl = buildListener;
            }

            public void poll() {
                List buildList = new ArrayList();

                Map three = new HashMap();
                three.put(BuildConstants.NAME_FIELD, "sample " + i++);
                three.put(BuildConstants.STATUS_FIELD, BuildConstants.STATUS_FAILED);
                buildList.add(three);

                Map blind = new HashMap();
                blind.put(BuildConstants.NAME_FIELD, "dimple " + i++);
                blind.put(BuildConstants.STATUS_FIELD, BuildConstants.STATUS_SUCCESSFUL);
                buildList.add(blind);

                bl.update(buildList);
            }
        });

        JFrame f = new JFrame("DamageControl");
        f.getContentPane().add(buildPanel.getPanel());
        f.pack();
        f.show();
    }
}