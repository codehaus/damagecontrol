package com.buildpatterns.damagecontrol.slave;

/**
 * @author Aslak Helles&oslash;y
 */
public class Main {
    public static void main(String[] args) {
        BuildSlave buildSlave = new BuildSlave(new Zipper());
        Agent agent = new Agent(buildSlave);
        agent.run();
    }
}
