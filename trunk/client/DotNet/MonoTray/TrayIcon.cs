// created on 11/6/2004 at 4:24 PM
using System;
using Egg;

namespace ThoughtWorks.DamageControl.MonoTray 
{
    public class DamageControlTrayIcon
    {
        private TrayIcon icon;
        private Gtk.Menu menu;
        
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
            eb.Add(new Gtk.Image(new Gdk.Pixbuf(null, "gray-24.png")));
            
            this.menu = new Gtk.Menu();
            
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
           
            Gtk.Application.Run ();            
         }

    	 private void IconClicked(object source, Gtk.ButtonPressEventArgs args)
	     {
		      menu.ShowAll();
		      menu.Popup (null, null, null, IntPtr.Zero, args.Event.Button, args.Event.Time); 
	     }
	 
	     private void QuitSelected(object source, EventArgs args)
	     {
	           Gtk.Application.Quit();
	     }
	     
	     private void SettingsSelected(object source, EventArgs args)
	     {
	           SettingsWindow sw = new SettingsWindow();
	     } 
    }
}
