package damagecontrol;

import com.rsslibj.elements.Channel;

import java.io.FileWriter;
import java.io.IOException;

import damagecontrol.Builder;
import damagecontrol.BuildEvent;

public class WriteRSSNotifier extends WriteToFileNotifier {
    public WriteRSSNotifier(Builder builder, String fileToWriteTo, String rootURL, String path) {
        super(builder, fileToWriteTo);
    }

    protected void writeOutput(FileWriter writer, BuildEvent evt) throws IOException {
        Channel channel = new Channel();
        channel.setDescription(evt.getOutput());
        channel.setLink("http://localhost/");
        channel.setTitle("My Channel");
        channel.setImage("http://localhost/",
                "The Channel Image",
                "http://localhost/foo.jpg");
        channel.setTextInput("http://localhost/search",
                "Search The Channel Image",
                "The Channel Image",
                "s");
        channel.addItem("http://localhost/item1",
                "The First Item covers details on the first item>",
                "The First Item")
                .setDcContributor("Joseph B. Ottinger");
        channel.addItem("http://localhost/item2",
                "The Second Item covers details on the second item",
                "The Second Item")
                .setDcCreator("Jason Bell");
        try {
            writer.write(channel.getFeed("rdf"));
        } catch (InstantiationException e) {
            e.printStackTrace();  //To change body of catch statement use Options | File Templates.
        } catch (IllegalAccessException e) {
            e.printStackTrace();  //To change body of catch statement use Options | File Templates.
        } catch (ClassNotFoundException e) {
            e.printStackTrace();  //To change body of catch statement use Options | File Templates.
        }
    }
}
