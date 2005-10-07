package com.buildpatterns.damagecontrol.slave;

/**
 * @author Aslak Helles&oslash;y
 */
public class Main {
    public static void main(String[] args) {
        Compresser compresser = new Zipper();
        BuildSlave buildSlave = new BuildSlave(compresser);
        Poster poster = new HttpClientPoster();
        Agent agent = new Agent(buildSlave, poster);

        agent.run();
    }
}
