package com.thoughtworks.damagecontrol.swing;

import java.util.List;
import java.util.Map;

/**
 * Represents the value in the drop down cells
 *
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.2 $
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

    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof BuildSet)) return false;

        final BuildSet buildSet = (BuildSet) o;

        if (!buildList.equals(buildSet.buildList)) return false;
        if (!selected.equals(buildSet.selected)) return false;

        return true;
    }

    public int hashCode() {
        int result;
        result = buildList.hashCode();
        result = 29 * result + selected.hashCode();
        return result;
    }
}