/*****************************************************************************
 * Copyright (C) NanoContainer Organization. All rights reserved.            *
 * ------------------------------------------------------------------------- *
 * The software in this package is published under the terms of the BSD      *
 * style license a copy of which has been included with this distribution in *
 * the LICENSE.txt file.                                                     *
 *                                                                           *
 * Original code by                                                          *
 *****************************************************************************/
package com.thoughtworks.damagecontrol.idea;

import com.intellij.openapi.components.ApplicationComponent;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.1 $
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
