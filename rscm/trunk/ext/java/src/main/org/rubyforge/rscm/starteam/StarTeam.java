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

import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Locale;
import java.util.Map;

import org.rubyforge.rscm.Change;
import org.rubyforge.rscm.ChangeSets;
import org.rubyforge.rscm.RSCM;

/**
 * Java helper for the RSCM implementation of StarTeam. This class has borrowed a lot from
 * CruiseControl's StarTeam class - but is highly simplified. It's still quite complex since
 * the native StarTeam API ermm... SUCKS.
 *
 * @author Aslak Helles&oslash;y
 */
public class StarTeam implements RSCM {
    private boolean canLookupEmails = true;
    private static final DateFormat ISO8601_FORMAT = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.UK);;
    private final String url;
    private final String folderName;

    public StarTeam(String url, String folderName) {
        this.url = url;
        this.folderName = folderName;
    }

    public StarTeam(String userName, String password, String serverName, String serverPort, String projectName, String viewName, String folderName) {
        this(userName + ":" + password + "@" + serverName + ":" + Integer.parseInt(serverPort) + "/" + projectName + "/" + viewName, folderName);
    }


    public ChangeSets getChangeSets(Date from, Date to) {
        System.out.println("CHANGESETS FOR " + url + " " + from + "-" + to + " - FOLDER:" + folderName);
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

            View snapshotAtFrom = new View(view, ViewConfiguration.createFromTime(new OLEDate(from)));

            if(to == null) {
                to = new Date();
            }
            OLEDate toDate = new OLEDate(to);
            View snapshotAtTo = new View(view, ViewConfiguration.createFromTime(toDate));

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
            } catch (Exception e) {
                e.printStackTrace();
            }
            compareFileLists(fromFiles, toFiles, toDate, changeSets);

            return changeSets;
        } finally {
            if (server != null) {
                server.disconnect();
            }
        }
    }

    /**
     * Compare old and new file lists to determine what happened
     */
    private void compareFileLists(Map fromFiles, Map toFiles, OLEDate toDate, ChangeSets changeSets) {
        for (Iterator iter = toFiles.keySet().iterator(); iter.hasNext();) {
            Integer currentItemID = (Integer) iter.next();
            File currentFile = (File) toFiles.get(currentItemID);

            if (fromFiles.containsKey(currentItemID)) {
                File lastBuildFile = (File) fromFiles.get(currentItemID);

                if (fileHasBeenModified(currentFile, lastBuildFile)) {
                    addRevision(currentFile, "MODIFIED", changeSets);
                } else if (fileHasBeenMoved(currentFile, lastBuildFile)) {
                    addRevision(currentFile, "MOVED", changeSets);
                }
                // Remove the identified last build file from the list of
                // last build files.  It will make processing the delete
                // check on the last builds quicker
                fromFiles.remove(currentItemID);
            } else {
                // File is new
                addRevision(currentFile, "ADDED", changeSets);
            }
        }
        examineOldFiles(fromFiles, changeSets, toDate);
    }

    /**
     * Now examine old files.  They have to have been deleted as we know they
     * are not in the new list from the processing above.
     */
    private void examineOldFiles(Map lastBuildFiles, ChangeSets changeSets, OLEDate toDate) {
        for (Iterator iter = lastBuildFiles.values().iterator(); iter.hasNext();) {
            File currentLastBuildFile = (File) iter.next();
            addRevision((File) currentLastBuildFile.getFromHistoryByDate(toDate), "DELETED", changeSets);
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

    private void addRevision(File revision, String status, ChangeSets changeSets) {
        User user = revision.getServer().getUser(revision.getModifiedBy());

//        System.out.println(revision.getParentFolder().getFolderHierarchy());
//        System.out.println(revision.getName());
//        System.out.println("----");

        String path = revision.getFullName();
        String prevRev = "" + (revision.getContentVersion() - 1);
        String rev = "" + revision.getContentVersion();
        Date time = null;
        final String timeString = revision.getModifiedTime().toISO8601String().substring(0, 19);
        try {
            time = ISO8601_FORMAT.parse(timeString);
//            System.out.println(Change.format(time));
        } catch (ParseException e) {
            throw new RuntimeException("Couldn't parse date: " + timeString, e);
        }
        Change change = new Change(user.getName(),
                revision.getComment(),
                path, prevRev,
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
}
