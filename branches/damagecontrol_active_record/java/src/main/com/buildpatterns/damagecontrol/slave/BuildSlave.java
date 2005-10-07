package com.buildpatterns.damagecontrol.slave;

import com.buildpatterns.damagecontrol.slave.types.BuildInfo;
import com.buildpatterns.damagecontrol.slave.types.BuildResult;
import com.buildpatterns.damagecontrol.slave.types.Revision;
import com.thoughtworks.xstream.XStream;
import com.thoughtworks.xstream.io.xml.DomDriver;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.Writer;
import java.util.Date;

/**
 * @author Aslak Helles&oslash;y
 */
public class BuildSlave {
    private final Compresser compresser;

    public BuildSlave(Compresser compresser) {
        this.compresser = compresser;
    }

    BuildInfo getBuildInfo(File buildInfo) throws FileNotFoundException {
        XStream xstream = new XStream();
        xstream.alias("build-info", BuildInfo.class);
        xstream.alias("revision", Revision.class);
        return (BuildInfo) xstream.fromXML(new FileReader(buildInfo));
    }

    public File execute(InputStream zip, File dir) throws IOException {
        compresser.unzip(zip, dir);
        BuildInfo buildInfo = getBuildInfo(new File(dir, "damagecontrol_build_info.xml"));
        FileOutputStream stdOut = new FileOutputStream(new File(dir, "stdout.log"));
        FileOutputStream stdErr = new FileOutputStream(new File(dir, "stderr.log"));
        return execute(buildInfo, dir, stdOut, stdErr);
    }

    private File execute(BuildInfo buildInfo, File dir, OutputStream stdOut, OutputStream stdErr) throws IOException {
        BuildResult buildResult = new BuildResult();
        try {
            buildResult.begintime = new Date(System.currentTimeMillis());
            final String[] envp = null;
            final String[] args = new String[]{"cmd.exe", "/C", buildInfo.buildcommand};
            Process process = Runtime.getRuntime().exec(args, envp, dir);
            InputStream stdOutIn = process.getInputStream();
            InputStream stdErrIn = process.getErrorStream();

            Thread stdOutPumper = new Thread(new StreamPumper(stdOutIn, stdOut));
            Thread stdErrPumper = new Thread(new StreamPumper(stdErrIn, stdErr));
            stdOutPumper.start();
            stdErrPumper.start();

            buildResult.exitstatus = new Integer(process.waitFor());
            stdOutPumper.join();
            stdErrPumper.join();
            process.destroy();
        } catch (IOException e) {
            e.printStackTrace();
        } catch (InterruptedException e) {
            e.printStackTrace();
        } finally {
            buildResult.endtime = new Date(System.currentTimeMillis());
        }
        writeBuildResult(dir, buildResult);
        return compresser.zip(dir);
    }

    private void writeBuildResult(File dir, BuildResult buildResult) throws IOException {
        XStream xstream = new XStream();
        xstream.alias("buildresult", BuildResult.class);
        Writer out = new BufferedWriter(new FileWriter(new File(dir, "damagecontrol_build_result.xml")));
        out.write(xstream.toXML(buildResult));
        out.flush();
        out.close();
    }

    private class AsyncKiller implements Runnable {
        private final Process p;
        private final long timeout;
        private boolean killed;

        AsyncKiller(final Process p, final long timeout) {
            this.p = p;
            this.timeout = timeout;
        }

        public void run() {
            try {
                Thread.sleep(timeout * 1000L);
                synchronized (this) {
                    p.destroy();
                    killed = true;
                }
            } catch (InterruptedException expected) {
            }
        }

        public synchronized boolean processKilled() {
            return killed;
        }
    }
}
