package damagecontrol;

import java.util.Iterator;
import java.util.Collection;
import java.util.ArrayList;

public abstract class AbstractBuilder implements Builder {
    public Collection buildListeners = new ArrayList();

    public AbstractBuilder(String name, Scheduler scheduler) {
        scheduler.registerBuilder(name, this);
    }

    public void build() {
        StringBuffer output = new StringBuffer();
        boolean result = doBuild(output);
        fireBuildFinished(new BuildEvent(this, result, output.toString()));
    }

    public abstract boolean doBuild(StringBuffer output);

    protected void fireBuildFinished(BuildEvent evt) {
        for (Iterator iterator = buildListeners.iterator(); iterator.hasNext();) {
            BuildListener buildListener = (BuildListener) iterator.next();
            buildListener.buildFinished(evt);
        }
    }

    public void addBuildListener(BuildListener buildListener) {
        buildListeners.add(buildListener);
    }
}
