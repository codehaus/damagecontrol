package org.rubyforge.rscm;

import junit.framework.TestCase;

import java.lang.reflect.InvocationTargetException;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision$
 */
public class StringCommandInvokerTest extends TestCase {

    public static class Mooky {
        public Mooky(String huba, String luba) {
            assertEquals("huba", huba);
            assertEquals("luba", luba);
        }

        public String jalla(String balla, String halla) {
            return halla + balla;
        }
    }

    public void testShouldParseCommandAndExecute() throws IllegalAccessException, NoSuchMethodException, InvocationTargetException, InstantiationException, ClassNotFoundException {
        StringCommandInvoker commandInvoker = new StringCommandInvoker(",");
        Object ret = commandInvoker.invoke("new org.rubyforge.rscm.StringCommandInvokerTest$Mooky(\"huba\",\"luba\").jalla(\"balla\",\"halla\")");
        assertEquals("hallaballa", ret);
    }
}
