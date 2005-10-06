package com.buildpatterns.damagecontrol.slave;

import com.buildpatterns.damagecontrol.slave.types.BuildInfo;
import com.buildpatterns.damagecontrol.slave.types.Revision;
import com.buildpatterns.damagecontrol.slave.types.BuildResult;
import com.thoughtworks.xstream.XStream;
import com.thoughtworks.xstream.io.xml.DomDriver;

import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.FileWriter;
import java.io.BufferedWriter;
import java.io.Writer;
import java.io.BufferedInputStream;
import java.io.FileInputStream;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;
import java.util.zip.ZipOutputStream;
import java.util.zip.CheckedOutputStream;
import java.util.zip.Adler32;
import java.util.Date;

/**
 * @author Aslak Helles&oslash;y
 */
public class BuildSlave {
    private final int BUFFER = 2048;

    void unzip(InputStream zip, File dir) throws IOException {
        dir.mkdirs();
        ZipInputStream zis = new ZipInputStream(zip);
        ZipEntry entry;
        while ((entry = zis.getNextEntry()) != null) {
            int count;
            byte data[] = new byte[BUFFER];
            FileOutputStream fos = new FileOutputStream(new File(dir, entry.getName()));
            BufferedOutputStream dest = new BufferedOutputStream(fos, BUFFER);
            while ((count = zis.read(data, 0, BUFFER)) != -1) {
                dest.write(data, 0, count);
            }
            dest.flush();
            dest.close();
        }
        zis.close();
    }

    BuildInfo getBuildInfo(File buildInfo) throws FileNotFoundException {
        XStream xstream = new XStream(new DomDriver());
        xstream.alias("build-info", BuildInfo.class);
        xstream.alias("revision", Revision.class);
        return (BuildInfo) xstream.fromXML(new FileReader(buildInfo));
    }

    public long execute(InputStream zip, File dir) throws IOException {
        unzip(zip, dir);
        BuildInfo buildInfo = getBuildInfo(new File(dir, "damagecontrol_build_info.xml"));
        FileOutputStream stdOut = new FileOutputStream(new File(dir, "stdout.log"));
        FileOutputStream stdErr = new FileOutputStream(new File(dir, "stderr.log"));
        return execute(buildInfo, dir, stdOut, stdErr);
    }

    private long execute(BuildInfo buildInfo, File dir, OutputStream stdOut, OutputStream stdErr) throws IOException {
        BuildResult buildResult = new BuildResult();
        try {
            buildResult.begintime = new Date(System.currentTimeMillis());
            final String[] envp = null;
            final String[] args = new String[]{"cmd.exe", "/C", "C:\\ruby\\bin\\rake.cmd"};
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
        return zip(dir);
    }

    /**
     * Zips the dir
     * @param dir
     * @return checksum
     * @throws IOException
     */
    private long zip(File dir) throws IOException {
        FileOutputStream zip = new FileOutputStream(dir.getAbsolutePath() + "_result.zip");
        CheckedOutputStream checksum = new CheckedOutputStream(zip, new Adler32());
        ZipOutputStream zos = new ZipOutputStream(new BufferedOutputStream(checksum));

        //out.setMethod(ZipOutputStream.DEFLATED);
        byte data[] = new byte[BUFFER];

        // get a list of files from current directory
        String rootDirName = dir.getAbsolutePath();
        addRecursively(rootDirName, dir, zos, data);

        zos.close();
        return checksum.getChecksum().getValue();
    }

    private void addRecursively(String rootDirName, File dir, ZipOutputStream zos, byte[] data) throws IOException {
        File files[] = dir.listFiles();

        for (int i = 0; i < files.length; i++) {
            if(files[i].isFile()) {
                FileInputStream fi = new FileInputStream(files[i]);
                BufferedInputStream origin = new BufferedInputStream(fi, BUFFER);
                String relativeFileName = files[i].getAbsolutePath().substring(rootDirName.length() + 1);
                ZipEntry entry = new ZipEntry(relativeFileName.replace('\\', '/'));
                zos.putNextEntry(entry);
                int count;
                while ((count = origin.read(data, 0, BUFFER)) != -1) {
                    zos.write(data, 0, count);
                }
                origin.close();
            } else {
                addRecursively(rootDirName, files[i], zos, data);
            }
        }
    }

    private void writeBuildResult(File dir, BuildResult buildResult) throws IOException {
        XStream xstream = new XStream(new DomDriver());
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
