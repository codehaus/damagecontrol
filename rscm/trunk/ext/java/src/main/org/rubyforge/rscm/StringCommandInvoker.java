package org.rubyforge.rscm;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Constructor;
import java.lang.reflect.Method;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Can parse simple strings and instantiate objects and call a method. String params only.
 *
 * @author Aslak Helles&oslash;y
 * @version $Revision$
 */
public class StringCommandInvoker {
    private static final Pattern newInvocationPattern = Pattern.compile("new ([^(]*)\\(([^)]*)\\)\\.([^(]*)\\(([^)]*)\\)");
    private final String argSeparator;

    public StringCommandInvoker(String argSeparator) {
        this.argSeparator = argSeparator;
    }

    public Object invoke(String command) throws ClassNotFoundException, NoSuchMethodException, IllegalAccessException, InvocationTargetException, InstantiationException {
        Matcher m = newInvocationPattern.matcher(command);
        if (m.matches()) {
            Class clazz = Class.forName(m.group(1));

            String[] ctorArgArray = toArgs(m.group(2));
            int ctorArgCount = ctorArgArray == null ? 0 : ctorArgArray.length;
            Constructor constructor = clazz.getConstructor(stringParamTypes(ctorArgCount));
            Object rscm = constructor.newInstance(ctorArgArray);

            String[] methodArgArray = toArgs(m.group(4));
            int methodArg = methodArgArray == null ? 0 : methodArgArray.length;
            Method method = clazz.getMethod(m.group(3), stringParamTypes(methodArg));
            return method.invoke(rscm, methodArgArray);
        } else {
            throw new RuntimeException("bad format:" + command);
        }
    }

    private Class[] stringParamTypes(int length) {
        final Class[] paramTypes = new Class[length];
        for (int i = 0; i < paramTypes.length; i++) {
            paramTypes[i] = String.class;
        }
        return paramTypes;
    }

    private String[] toArgs(String s) {
        if(s.equals("")) {
            return(null);
        }
        String[] argArray = s.split(argSeparator);
        for (int i = 0; i < argArray.length; i++) {
            argArray[i] = argArray[i].replace('"', ' ').trim();
        }
        return argArray;
    }
}
