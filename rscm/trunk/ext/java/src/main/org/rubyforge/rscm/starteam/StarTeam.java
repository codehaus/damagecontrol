package org.rubyforge.rscm.starteam;

import com.starbase.starteam.File;
import com.starbase.starteam.Folder;
import com.starbase.starteam.Item;
import com.starbase.starteam.PropertyNames;
import com.starbase.starteam.Server;
import com.starbase.starteam.ServerException;
import com.starbase.starteam.StarTeamFinder;
import com.starbase.starteam.User;
import com.starbase.starteam.UserAccount;
import com.starbase.starteam.View;
import com.starbase.starteam.ViewConfiguration;
import com.starbase.util.OLEDate;
import org.apache.tools.ant.BuildEvent;
import org.apache.tools.ant.BuildListener;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Target;
import org.apache.tools.ant.Task;
import org.apache.tools.ant.taskdefs.optional.starteam.StarTeamCheckout;
import org.apache.tools.ant.taskdefs.optional.starteam.StarTeamTask;
import org.rubyforge.rscm.Change;
import org.rubyforge.rscm.ChangeSets;
import org.rubyforge.rscm.RSCM;
import org.rubyforge.rscm.YamlDumpable;
import org.rubyforge.rscm.YamlList;

import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Locale;
import java.util.Map;
import java.util.TimeZone;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Java helper for the RSCM implementation of StarTeam. This class has borrowed a lot of code from
 * CruiseControl's StarTeam class (for changesets) and from Ant (for checkout).
 *
 * @author Aslak Helles&oslash;y
 */
public class StarTeam implements RSCM {

    // Used to parse dates coming from Ruby
    // http://hedwig.sourceforge.net/xref/org/apache/james/util/RFC822Date.html
    private static final DateFormat dx = new SimpleDateFormat("EE, d MMM yyyy HH:mm:ss zzzzz", Locale.UK);
    private static final DateFormat dy = new SimpleDateFormat("EE d MMM yyyy HH:mm:ss zzzzz", Locale.UK);
    private static final DateFormat dz = new SimpleDateFormat("d MMM yyyy HH:mm:ss zzzzz", Locale.UK);
    // Used to parse dates coming from StarTeam
    private static final DateFormat ISO8601_FORMAT = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.UK);;
    private static final TimeZone GMT = TimeZone.getTimeZone("GMT");

    static {
        dx.setTimeZone(GMT);
        dy.setTimeZone(GMT);
        dz.setTimeZone(GMT);
        ISO8601_FORMAT.setTimeZone(GMT);
    }

    private static final Pattern removingProcessesPattern = Pattern.compile("removing processed (.*) from UnmatchedFileMap");
    // See abstract_scm.rb
    private static final Date INFINITY = parseRfc822("1 Jan 2038 00:00:00 -0000");

    private boolean canLookupEmails = true;
    private final String userName;
    private final String password;
    private final String serverName;
    private final String serverPort;
    private final String projectName;
    private final String viewName;
    private final String folderName;
    private final String url;

    private Pattern checkingOutPattern;
    private Pattern relativePathPattern;
    private Map checkedOutStarTeamFileToFileSystemFiles = new HashMap();

    public StarTeam(String userName, String password, String serverName, String serverPort, String projectName, String viewName, String folderName) {
        this.userName = userName;
        this.password = password;
        this.serverName = serverName;
        this.serverPort = serverPort;
        this.projectName = projectName;
        this.viewName = viewName;
        this.folderName = folderName;

        this.url = userName + ":" + password + "@" + serverName + ":" + Integer.parseInt(serverPort) + "/" + projectName + "/" + viewName;

        String pathPrefixRegexp = viewName;
        if(folderName != null && !folderName.equals("")) {
            pathPrefixRegexp += "." + folderName;
        }
        pathPrefixRegexp += ".";

        // compute regexp to match the relative paths for changesets.
        relativePathPattern = Pattern.compile(pathPrefixRegexp + "(.*)", Pattern.DOTALL);

        // compute regexp to match the checked out files.
        checkingOutPattern = Pattern.compile("Checking out: " + pathPrefixRegexp + "(.*) \\-\\-> (.*)", Pattern.DOTALL);
    }

    public YamlDumpable getChangeSets(String fromSpecifier, String toSpecifier) {
        Date from = parseRfc822(fromSpecifier);
        Date to = parseRfc822(toSpecifier);

        ChangeSets changeSets = new ChangeSets();

        Server server = null;
        try {
            // Set up two view snapshots, one at lastbuild time, one to
            View view = StarTeamFinder.openView(url);

            if (view == null) {
                throw new RuntimeException("Can't find view: " + view);
            }
            server = view.getServer();

            PropertyNames stPropertyNames = server.getPropertyNames();

            // properties to fetch immediately and cache
            final String[] propertiesToCache =
                    new String[]{
                        stPropertyNames.FILE_CONTENT_REVISION,
                        stPropertyNames.MODIFIED_TIME,
                        stPropertyNames.FILE_FILE_TIME_AT_CHECKIN,
                        stPropertyNames.COMMENT,
                        stPropertyNames.MODIFIED_USER_ID,
                        stPropertyNames.FILE_NAME};

            OLEDate fromDate = new OLEDate(from);
            View snapshotAtFrom = new View(view, ViewConfiguration.createFromTime(fromDate));

            ViewConfiguration toConfig;
            OLEDate toDate;
            if(INFINITY.equals(to)) {
                toDate = new OLEDate(new Date());
                toConfig = ViewConfiguration.createTip();
            } else {
                toDate = new OLEDate(to);
                toConfig = ViewConfiguration.createFromTime(toDate);
            }
            View snapshotAtTo = new View(view, toConfig);

            // cache information for to
            Folder toRootFolder = snapshotAtTo.getRootFolder();
            Folder toRoot = StarTeamFinder.findFolder(toRootFolder, folderName);
            toRoot.populateNow(server.getTypeNames().FILE, propertiesToCache, -1);
            Map toFiles = new HashMap();
            recurse(toFiles, toRoot);

            Map fromFiles = new HashMap();
            try {
                Folder fromRootFolder = snapshotAtFrom.getRootFolder();
                Folder fromRoot = StarTeamFinder.findFolder(fromRootFolder, folderName);
                fromRoot.populateNow(server.getTypeNames().FILE, propertiesToCache, -1);
                recurse(fromFiles, fromRoot);
            } catch (com.starbase.starteam.ServerException ignore) {
                // This typically happens when fromTime is epoch. We can live without recurse the first time.
            }

            compareFileLists(fromFiles, toFiles, changeSets, fromDate, toDate);

            return changeSets;
        } finally {
            if (server != null) {
                server.disconnect();
            }
        }
    }

    private void antInit(Task task, BuildListener buildListener) {
        Project project = new Project();
        project.init();
//        final DefaultLogger defaultLogger = new DefaultLogger();
//        defaultLogger.setOutputPrintStream(System.out);
//        project.addBuildListener(defaultLogger);
        project.addBuildListener(buildListener);
        task.setProject(project);
        task.setTaskType("stcheckout");
        task.setTaskName("stcheckout");
        task.setOwningTarget(new Target());
    }

    private void starteamInit(StarTeamTask task) {
        task.setUserName(userName);
        task.setPassword(password);
        task.setProjectname(projectName);
        task.setViewname(viewName);
        task.setServername(serverName);
        task.setServerport(serverPort);
    }

    public YamlDumpable checkout(String dir) {
        StarTeamCheckout checkout = new StarTeamCheckout();
        final YamlList checkedOutFiles = new YamlList();
        BuildListener buildListener = new BuildListener() {
            public void buildStarted(BuildEvent event) {
            }

            public void buildFinished(BuildEvent event) {
            }

            public void targetStarted(BuildEvent event) {
            }

            public void targetFinished(BuildEvent event) {
            }

            public void taskStarted(BuildEvent event) {
            }

            public void taskFinished(BuildEvent event) {
            }

            public void messageLogged(BuildEvent event) {
                final String message = event.getMessage();
                if (event.getPriority() == 2) {
                    Matcher checkingOutMatcher = checkingOutPattern.matcher(message.trim());
                    if (checkingOutMatcher.matches()) {
                        String starTeamPath = checkingOutMatcher.group(1).replace('\\', '/');
                        String fileSystemPath = checkingOutMatcher.group(2);
                        // we have to stick it on the path, because it is only when we get a
                        // removing processed that the file exists on disk, and we can check
                        // whether the file is a dir or a file.
                        checkedOutStarTeamFileToFileSystemFiles.put(fileSystemPath, starTeamPath);
                    } else {
                    }
                } else if (event.getPriority() == 4) {
                    Matcher removingProcessedMatcher = removingProcessesPattern.matcher(message.trim());
                    if (removingProcessedMatcher.matches()) {
                        String fileSystemPath = removingProcessedMatcher.group(1);
                        java.io.File file = new java.io.File(fileSystemPath);
                        if (file.isFile()) {
                            String starTeamPath = (String) checkedOutStarTeamFileToFileSystemFiles.remove(fileSystemPath);
System.out.println(starTeamPath);
System.err.println(starTeamPath);
                            if(starTeamPath != null) {
                                checkedOutFiles.add(starTeamPath);
                                // Print to stdout so it can be intercepted
                                // by Ruby and yielded.
                                System.out.println(starTeamPath);
                                System.err.println(starTeamPath);
                            }
                        }
                    }
                }
            }
        };

        antInit(checkout, buildListener);
        starteamInit(checkout);
        checkout.setRootStarteamFolder(folderName);

        checkout.setRootLocalFolder(dir);
        checkout.execute();
        System.out.println("**********");
        return checkedOutFiles;
    }

    /**
     * Compare old and new file lists to determine what happened
     */
    private void compareFileLists(Map fromFiles, Map toFiles, ChangeSets changeSets, OLEDate fromDate, OLEDate toDate) {
        for (Iterator iter = toFiles.keySet().iterator(); iter.hasNext();) {
            Integer currentItemID = (Integer) iter.next();
            File currentFile = (File) toFiles.get(currentItemID);

            if (fromFiles.containsKey(currentItemID)) {
                File lastBuildFile = (File) fromFiles.get(currentItemID);

                if (fileHasBeenModified(currentFile, lastBuildFile)) {
                    addRevision(currentFile, "MODIFIED", changeSets, fromDate, toDate);
                } else if (fileHasBeenMoved(currentFile, lastBuildFile)) {
                    addRevision(currentFile, "MOVED", changeSets, fromDate, toDate);
                }
                // Remove the identified last build file from the list of
                // last build files.  It will make processing the delete
                // check on the last builds quicker
                fromFiles.remove(currentItemID);
            } else {
                // File is new
                addRevision(currentFile, "ADDED", changeSets, fromDate, toDate);
            }
        }
        examineOldFiles(fromFiles, changeSets, fromDate, toDate);
    }

    /**
     * Now examine old files.  They have to have been deleted as we know they
     * are not in the new list from the processing above.
     */
    private void examineOldFiles(Map lastBuildFiles, ChangeSets changeSets, OLEDate fromDate, OLEDate toDate) {
        for (Iterator iter = lastBuildFiles.values().iterator(); iter.hasNext();) {
            File currentLastBuildFile = (File) iter.next();
            addRevision((File) currentLastBuildFile.getFromHistoryByDate(toDate), "DELETED", changeSets, fromDate, toDate);
        }
    }

    private boolean fileHasBeenModified(File currentFile, File lastBuildFile) {
        return currentFile.getContentVersion() != lastBuildFile.getContentVersion();
    }

    private boolean fileHasBeenMoved(File currentFile, File lastBuildFile) {
        return !currentFile.getParentFolder().getFolderHierarchy().equals(lastBuildFile.getParentFolder().getFolderHierarchy());
    }

    private void recurse(Map fileList, Folder folder) {
        Item[] files = folder.getItems("File");
        for (int i = 0; i < files.length; i++) {
            fileList.put(new Integer(files[i].getItemID()), files[i]);
        }

        Folder[] folders = folder.getSubFolders();
        for (int i = 0; i < folders.length; i++) {
            recurse(fileList, folders[i]);
        }
    }

    private void addRevision(File revision, String status, ChangeSets changeSets, OLEDate fromDate, OLEDate toDate) {
        String path = (revision.getParentFolderHierarchy() + revision.getName()).replace('\\', '/');

        OLEDate modifiedTime = revision.getModifiedTime();
        if(modifiedTime.getLongValue() < fromDate.getLongValue() || toDate.getLongValue() < modifiedTime.getLongValue()) {
            // Outside time range
            // System.err.println("Outside: " + path + ":" + modifiedTime.toISO8601String());
            return;
        }

        User user = revision.getServer().getUser(revision.getModifiedBy());

        Matcher m = relativePathPattern.matcher(path);
        if(m.matches()) {
            path = m.group(1);
        } else {
            throw new RuntimeException(path + " doesn't match regexp " + relativePathPattern.pattern());
        }
        String prevRev = "" + (revision.getContentVersion() - 1);
        String rev = "" + revision.getContentVersion();
        Date time = null;
        final String isoString = modifiedTime.toISO8601String();
        try {
            time = ISO8601_FORMAT.parse(isoString);
        } catch (ParseException e) {
            throw new RuntimeException("Couldn't parse date: " + isoString, e);
        }
        Change change = new Change(user.getName(),
                revision.getComment(),
                path,
                prevRev,
                rev,
                status,
                time);

        if (user != null && canLookupEmails) {
            // Try to obtain email to add.  This is only allowed if logged on
            // user is SERVER ADMINISTRATOR
            try {
                // check if user account exists
                UserAccount useracct = user.getServer().getAdministration().findUserAccount(user.getID());
                if (useracct != null) {
//                    change.emailAddress = useracct.getEmailAddress();
                }
            } catch (ServerException sx) {
                // Logged on user does not have permission to get user's email.
                // Return the modifying user's name instead. Then use the
                // email.properties file to map the name to an email address
                // outside of StarTeam
                canLookupEmails = false;
            }
        }

        changeSets.add(change);
    }

    private static Date parseRfc822(String rfcdate) {
        if(rfcdate.equals("")) {
            return null;
        }
        try {
            return dx.parse(rfcdate);
        } catch (ParseException e) {
            try {
                return dz.parse(rfcdate);
            } catch (ParseException f) {
                try {
                    return dy.parse(rfcdate);
                } catch (ParseException g) {
                    throw new RuntimeException(g);
                }
            }
        }
    }
}
