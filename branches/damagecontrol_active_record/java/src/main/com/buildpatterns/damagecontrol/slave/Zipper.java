package com.buildpatterns.damagecontrol.slave;

import java.io.File;
import java.io.IOException;
import java.io.FileOutputStream;
import java.io.BufferedOutputStream;
import java.io.InputStream;
import java.io.FileInputStream;
import java.io.BufferedInputStream;
import java.util.zip.CheckedOutputStream;
import java.util.zip.Adler32;
import java.util.zip.ZipOutputStream;
import java.util.zip.ZipInputStream;
import java.util.zip.ZipEntry;

/**
 * @author Aslak Helles&oslash;y
 */
public class Zipper implements Compresser {
    private static final int BUFFER = 2048;

    /**
     * Zips the dir
     *
     * @param dir
     * @return the zipped result
     * @throws java.io.IOException
     */
    public File zip(File dir) throws IOException {
        File resultZip = new File(dir.getAbsolutePath() + "_result.zip");
        FileOutputStream zip = new FileOutputStream(resultZip);
        CheckedOutputStream checksum = new CheckedOutputStream(zip, new Adler32());
        ZipOutputStream zos = new ZipOutputStream(new BufferedOutputStream(checksum));

        //out.setMethod(ZipOutputStream.DEFLATED);
        byte data[] = new byte[BUFFER];

        // get a list of files from current directory
        String rootDirName = dir.getAbsolutePath();
        addRecursively(rootDirName, dir, zos, data);

        zos.close();
        System.out.println("Checksum:" + checksum.getChecksum().getValue());
        return resultZip;
    }

    public void unzip(InputStream zip, File dir) throws IOException {
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

    private void addRecursively(String rootDirName, File dir, ZipOutputStream zos, byte[] data) throws IOException {
        File files[] = dir.listFiles();

        for (int i = 0; i < files.length; i++) {
            if (files[i].isFile()) {
                BufferedInputStream file = new BufferedInputStream(new FileInputStream(files[i]), BUFFER);
                String relativeFileName = files[i].getAbsolutePath().substring(rootDirName.length() + 1);
                ZipEntry entry = new ZipEntry(relativeFileName.replace('\\', '/'));
                zos.putNextEntry(entry);
                int count;
                while ((count = file.read(data, 0, BUFFER)) != -1) {
                    zos.write(data, 0, count);
                }
                file.close();
            } else {
                addRecursively(rootDirName, files[i], zos, data);
            }
        }
    }

}
