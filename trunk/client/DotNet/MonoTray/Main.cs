// project created on 11/5/2004 at 9:19 PM
using System;
using Gtk;
using Glade;

public class GladeApp
{
        public static void Main (string[] args)
        {
                new GladeApp (args);
        }

        public GladeApp (string[] args) 
        {
                Application.Init();

                Glade.XML gxml = new Glade.XML (null, "gui.glade", "window1", null);
                gxml.Autoconnect (this);
                Application.Run();
        }

        /* Connect the Signals defined in Glade */
        public void OnWindowDeleteEvent (object o, DeleteEventArgs args) 
        {
                Application.Quit ();
                args.RetVal = true;
        }
}

