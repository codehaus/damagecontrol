// created on 11/6/2004 at 4:24 PM
using System;
using Egg;
using Nwc.XmlRpc;
using System.Collections;
using System.Net;
using ThoughtWorks.DamageControl.DamageControlClientNet;
using Chicken.Gnome.Notification;

namespace ThoughtWorks.DamageControl.MonoTray 
{
    
    public class DamageControlTrayIcon
    {
        private TrayIcon icon;
        private Gtk.Menu menu;
        public ArrayList projects;
        private Gtk.Image image;
        private Gdk.Pixbuf pixbuf;
        
        private void InitializeSettings()
        {
			try 
			{
			     Console.WriteLine(Settings.NotificationMessages);
			}
			catch (Exception e)
			{
			     Settings.NotificationMessages = true;
			}
			try 
			{
			     Console.WriteLine(Settings.PlayWhenFailing);
			}
			catch (Exception e)
			{
			     Settings.PlayWhenFailing = false;
			}
			try 
			{
			     Console.WriteLine(Settings.PlayWhenStillFailing);
			}
			catch (Exception e)
			{
			     Settings.PlayWhenStillFailing = false;
			}
			try 
			{
			     Console.WriteLine(Settings.PlayWhenStillSuccessful);
			}
			catch (Exception e)
			{
			     Settings.PlayWhenStillSuccessful = false;
			}
			try 
			{
			     Console.WriteLine(Settings.PlayWhenSuccessful);
			}
			catch (Exception e)
			{
			     Settings.PlayWhenSuccessful = false;
			}
			
			try 
			{
			     Console.WriteLine(Settings.SuccessfulSound);
			}
			catch (Exception e)
			{
			     Settings.SuccessfulSound = "";
			}
			try 
			{
			     Console.WriteLine(Settings.FailingSound);
			}
			catch (Exception e)
			{
			     Settings.FailingSound = "";
			}
			try 
			{
			     Console.WriteLine(Settings.StillFailingSound);
			}
			catch (Exception e)
			{
			     Settings.StillFailingSound = "";
			}
			try 
			{
			     Console.WriteLine(Settings.StillSuccessfulSound);
			}
			catch (Exception e)
			{
			     Settings.StillSuccessfulSound = "";
			}
        }
        
        public DamageControlTrayIcon()
        {
            Gtk.Application.Init();
            this.icon = new TrayIcon("DamageControl Monitor");  
            
            InitializeSettings();
            Gtk.EventBox eb = new Gtk.EventBox();
            
            eb.ButtonPressEvent += new Gtk.ButtonPressEventHandler(IconClicked);
            pixbuf = new Gdk.Pixbuf(null, "gray-24.png");
            image = new Gtk.Image(pixbuf);
            eb.Add(image);
            
            this.menu = new Gtk.Menu();
            this.projects = MonoTray.LoadSettings();
            
            foreach (Project p in this.projects)
                p.StartPolling();
            
            Gtk.AccelGroup ac_quit = new Gtk.AccelGroup();
            Gtk.ImageMenuItem it_quit  = new Gtk.ImageMenuItem (Gtk.Stock.Quit, ac_quit);
		    it_quit.Activated += new EventHandler (QuitSelected);
		    
		    
		    Gtk.AccelGroup ac_settings = new Gtk.AccelGroup();
		    Gtk.ImageMenuItem it_settings = new Gtk.ImageMenuItem(Gtk.Stock.Preferences, ac_settings);
		    it_settings.Activated += new EventHandler(SettingsSelected);
		    
		    menu.Append(it_settings);
		    menu.Append (it_quit);

            
            this.icon.Add(eb);
            
            this.icon.ShowAll ();
            
            UpdateProxy();
            UpdateProjectList();
           
            Gtk.Application.Run ();
         }
         
         private void UpdateProjectList() {
            foreach (Project proj in this.projects)
                proj.OnPolled += new PolledEventHandler(ProjectPolled);
         }
         
         public void BuildOccurred(object source, BuildOccurredEventArgs args)
         {
            Console.WriteLine("Build Occurred");
                     
         }
         
         public void ProjectPolled(object source, PolledEventArgs args)
		 {
		     bool onefailed = false;
		     bool onesucceeded = false;
		     foreach (Project proj in this.projects)
		     {
                if (proj.ProjectStatus.BuildStatus == BuildStatus.Success)
                    onesucceeded = true;
                if (proj.ProjectStatus.BuildStatus == BuildStatus.Failure)
                    onefailed = true;
                if (onefailed)
                {
                    //image = new Gtk.Image(new Gdk.Pixbuf(null, "red-24.png"));
                    pixbuf = new Gdk.Pixbuf(null, "red-24.png");
                    image.Pixbuf = pixbuf;
                    image.ShowNow();
                    return;
                }
                else if (onesucceeded)
                {
                    pixbuf = new Gdk.Pixbuf(null, "green-24.png");
                    image.Pixbuf = pixbuf;
                    image.ShowNow();
                    return;
                }
                else
                {
                    pixbuf = new Gdk.Pixbuf(null, "gray-24.png");
                    image.Pixbuf = pixbuf;
                    image.ShowNow();
                    Console.WriteLine("gray");
                }
             }
		 }
         
         private void UpdateProxy() 
		 {
			RequestSettings settings = RequestSettings.getInstance();
            GConf.Client client = new GConf.Client ();
            try {
                bool use = (bool) client.Get("/system/http_proxy/use_http_proxy");
                if (!use)
                    return;
                string host = (string) client.Get("/system/http_proxy/host");
                if (host==null)
                    return;
                int port = (int) client.Get("/system/http_proxy/port");
			    if (port<=0)
			        return;
			    Console.WriteLine("Proxy " +  host + ":" + port);
			    settings.Proxy = new WebProxy(host, port);
			 }
			 catch (Exception e) {}
		 }

    	 private void IconClicked(object source, Gtk.ButtonPressEventArgs args)
	     {
	          //ProjectWindow pw = new ProjectWindow();
	          //pw.Show();
		      menu.ShowAll();
		      menu.Popup (null, null, null, IntPtr.Zero, args.Event.Button, args.Event.Time); 
	     }
	 
	     private void QuitSelected(object source, EventArgs args)
	     {
	           MonoTray.SaveProjects(this.projects);
	           Gtk.Application.Quit();
	           Environment.Exit(0);
	     }
	     
	     private void SettingsSelected(object source, EventArgs args)
	     {
	           SettingsWindow sw = new SettingsWindow(this.projects, this);
	     } 
    }
}
