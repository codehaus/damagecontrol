package org.rubyforge.rscm;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileReader;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.Reader;
import java.io.Writer;
import java.lang.reflect.InvocationTargetException;

/**
 * Main class intended to be invoked from Ruby. Prints RSCM::ChangeSets YAML to
 * stdout, which can in turn be easily YAML::read into Ruby objects.
 *
 * @author Aslak Helles&oslash;y
 */
public class Main {

    public Main(Reader in, Writer out) throws IOException, ClassNotFoundException, NoSuchMethodException, IllegalAccessException, InvocationTargetException, InstantiationException {
        String command = new BufferedReader(in).readLine();
        Object result = new StringCommandInvoker(";").invoke(command);
        if(result instanceof YamlDumpable) {
            ((YamlDumpable) result).dumpYaml(out);
            out.flush();
        }
    }

    public static void main(String[] args) throws IOException, ClassNotFoundException, NoSuchMethodException, IllegalAccessException, InvocationTargetException, InstantiationException {
        new Main(new BufferedReader(new FileReader(args[0])), new BufferedWriter(new OutputStreamWriter(System.out)));
    }
}
