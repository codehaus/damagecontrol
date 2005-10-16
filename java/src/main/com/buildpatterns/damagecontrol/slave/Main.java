package com.buildpatterns.damagecontrol.slave;

import java.io.IOException;

/**
 * @author Aslak Helles&oslash;y
 */
public class Main {
    public static void main(String[] args) throws IOException {
        Compresser compresser = new Zipper();
        CompressingBuildExecutor buildSlave = new CompressingBuildExecutor(compresser);
        Poster poster = new HttpClientPoster();
        Agent agent = new Agent(buildSlave, poster, null);

        agent.buildNext();
    }
}
