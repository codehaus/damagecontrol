package damagecontrol.scm.cvsx;

import org.apache.tools.ant.*;
import org.apache.tools.ant.BuildEvent;
import org.apache.tools.ant.BuildListener;

import java.io.File;

import junit.framework.TestCase;
import damagecontrol.NullBuilder;

/**
 * This class tests interoperation with CVS. It uses Ant to set up
 * and configure a temporary CVS repository (because this is easier to
 * do in a build.xml than from Java). This class is inspired from
 * Ant's own test suite's BuildFileTest.java.
 * <p>
 * This class is not really a unit test (it doesn't test a particular class).
 * It is an integration test that tests end-to-end functionality of
 * DamageControl.
 *
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.1 $
 */
public class CvsIntegrationTest extends TestCase {

    public void testCompleteBuildCycle() throws Exception {
        Project project = new Project();
        project.init();
        ProjectHelper.configureProject(project, new File("src/test/damagecontrol/scm/cvsx/build.xml"));
        project.addBuildListener(new BuildListener() {
            public void buildStarted(BuildEvent event) {}
            public void buildFinished(BuildEvent event) {}
            public void targetStarted(BuildEvent event) {}
            public void targetFinished(BuildEvent event) {}
            public void taskStarted(BuildEvent event) {}
            public void taskFinished(BuildEvent event) {}

            public void messageLogged(BuildEvent event) {
                if (event.getPriority() == Project.MSG_ERR) {
                    String msg = event.getMessage();
                    String prefix = "OUTPUT:";
                    if(msg.startsWith(prefix)) {
                        String fileContent = msg.substring(prefix.length());
                        assertEquals(NullBuilder.SUCCESS_MESSAGE, fileContent);
                    }
                }
            }

        });
        project.executeTarget("complete-build-cycle");
        // No asserts here, assertions are done from the ant script,
        // and finally in the build listener above, where we compare the
        // contents of the file written to disk.
    }

}
