package com.thoughtworks.damagecontrol.swing;

import com.thoughtworks.damagecontrol.buildmonitor.BuildConstants;
import com.thoughtworks.damagecontrol.buildmonitor.BuildListener;
import com.thoughtworks.damagecontrol.buildmonitor.BuildPoller;
import com.thoughtworks.damagecontrol.buildmonitor.marquee.MarqueeXmlRpcBuildPoller;

import javax.swing.JFrame;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.5 $
 */
public class BuildPanelDemo {
    private static BuildListener bl;
    private static int i;

    public static void main(String[] args) throws MalformedURLException {
        BuildPanelData buildPanel = new BuildPanelData(createDemoPoller());
//        BuildPanelData buildPanel = new BuildPanelData(new MarqueeXmlRpcBuildPoller(new URL("http://beaver.codehaus.org:4712/xmlrpc")));
//        BuildPanelData buildPanel = new BuildPanelData(new MarqueeXmlRpcBuildPoller(new URL("http://localhost:4712/xmlrpc")));

        JFrame f = new JFrame("DamageControl");
        f.getContentPane().add(buildPanel.getPanel());
        f.pack();
        f.show();
    }

    private static BuildPoller createDemoPoller() {
        return new BuildPoller(){
                    public void addBuildListener(BuildListener buildListener) {
                        bl = buildListener;
                    }

                    public void poll() {
                        List appleList = new ArrayList();
                        Map apple1 = new HashMap();
                        apple1.put(BuildConstants.PROJECT_NAME_FIELD, "apple " + i++);
                        apple1.put(BuildConstants.STATUS_FIELD, BuildConstants.STATUS_FAILED);
                        apple1.put(BuildConstants.TIMESTAMP_FIELD, String.valueOf(new Date().getTime()));
                        appleList.add(apple1);

                        Map apple2 = new HashMap();
                        apple2.put(BuildConstants.PROJECT_NAME_FIELD, "apple " + i++);
                        apple2.put(BuildConstants.STATUS_FIELD, BuildConstants.STATUS_BUILDING);
                        apple2.put(BuildConstants.TIMESTAMP_FIELD, String.valueOf(new Date().getTime()));
                        appleList.add(apple2);

                        List pearList = new ArrayList();
                        Map pear1 = new HashMap();
                        pear1.put(BuildConstants.PROJECT_NAME_FIELD, "pear " + i++);
                        pear1.put(BuildConstants.STATUS_FIELD, BuildConstants.STATUS_QUEUED);
                        pear1.put(BuildConstants.TIMESTAMP_FIELD, String.valueOf(new Date().getTime()));
                        pearList.add(pear1);

                        Map buildListMap = new HashMap();
                        buildListMap.put("apple", appleList);
                        buildListMap.put("pear", pearList);
                        bl.update(buildListMap);
                    }
                };
    }
}