package com.thoughtworks.damagecontrol.swing;

import java.util.List;
import java.util.Map;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.1 $
 */
public class BuildSet {
    private final List buildList;
    private Map selected;

    public BuildSet(List buildList) {
        this.buildList = buildList;
        selected = (Map) buildList.get(buildList.size() - 1);
    }

    public List getBuilds() {
        return buildList;
    }

    public Map getSelected() {
        return selected;
    }

    public void setSelected(Map selected) {
        this.selected = selected;
    }
}