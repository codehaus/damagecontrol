package com.thoughtworks.damagecontrol.idea;

import com.intellij.openapi.components.ApplicationComponent;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.2 $
 */
public class IDEAPlugin implements ApplicationComponent {
    public String getComponentName() {
        return "DamageControl";
    }

    public void initComponent() {

    }

    public void disposeComponent() {

    }
}
