/*
 * Created on Oct 15, 2005
 *
 * TODO To change the template for this generated file go to
 * Window - Preferences - Java - Code Style - Code Templates
 */
package com.buildpatterns.damagecontrol.slave;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;

/**
 * @author aslakhellesoy
 *
 * TODO To change the template for this generated type comment go to
 * Window - Preferences - Java - Code Style - Code Templates
 */
public interface BuildExecutor {
	File execute(InputStream zip, File dir) throws IOException;
}