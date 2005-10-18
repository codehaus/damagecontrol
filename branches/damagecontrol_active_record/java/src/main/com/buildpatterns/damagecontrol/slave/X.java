package com.buildpatterns.damagecontrol.slave;

import com.buildpatterns.damagecontrol.slave.types.BuildInfo;
import com.buildpatterns.damagecontrol.slave.types.BuildResult;
import com.buildpatterns.damagecontrol.slave.types.PendingBuildInfo;
import com.buildpatterns.damagecontrol.slave.types.Revision;
import com.thoughtworks.xstream.XStream;

public class X {
	public static XStream stream = new XStream();
	static {
        stream.alias("build-info", BuildInfo.class);
        stream.alias("buildresult", BuildResult.class);
        stream.alias("revision", Revision.class);
        stream.alias("pending-build-info", PendingBuildInfo.class);
	}
}
