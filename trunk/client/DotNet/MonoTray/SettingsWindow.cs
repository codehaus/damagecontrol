// created on 11/6/2004 at 3:29 PM
using System;
using ThoughtWorks.DamageControl.DamageControlClientNet;
using Gtk;
using Glade;
using System.Collections;

namespace ThoughtWorks.DamageControl.MonoTray {

	public class SettingsWindow
	{
	
	    private ArrayList projects;
	    
		[Widget] Button closeSettingsButton;
		[Widget] Button newButton;
		[Widget] Window settingsWindow;
		
		public SettingsWindow (ArrayList p)
		{
			Glade.XML gxml = new Glade.XML (null, "gui.glade", "settingsWindow", null);
			gxml.Autoconnect (this);
			
			this.projects = p;
			
			GConf.PropertyEditors.EditorShell shell = 
			  new GConf.PropertyEditors.EditorShell (gxml);
			  
			shell.Add (SettingKeys.NotificationMessages, "unm", typeof(bool));
			
			shell.Add (SettingKeys.PlayWhenFailing, "failedCheckbox", typeof(bool));
		    shell.Add (SettingKeys.PlayWhenStillFailing, "stillfailingCheckbox", typeof(bool));
			shell.Add (SettingKeys.PlayWhenStillSuccessful, "stillsuccessfulCheckbox", typeof(bool));
			shell.Add (SettingKeys.PlayWhenSuccessful, "successfulCheckbox", typeof(bool));
			
			shell.Add (SettingKeys.SuccessfulSound, "successfulEntry", typeof(string));
			shell.Add (SettingKeys.StillSuccessfulSound, "stillsuccessfulEntry", typeof(string));
			shell.Add (SettingKeys.FailingSound, "failedEntry", typeof(string));
			shell.Add (SettingKeys.StillFailingSound, "stillfailingEntry", typeof(string));
			
			this.closeSettingsButton.Clicked += closeSettings; 
			this.newButton.Clicked += newProject;
		}
		
		public void OnWindowDeleteEvent (object o, DeleteEventArgs args) 
		{
			closeSettings(o, args);
		}
		
		public void Show()
		{
		     this.settingsWindow.ShowAll();
		}

		private void closeSettings(object source, EventArgs args)
		{
			this.settingsWindow.Hide();
			this.settingsWindow.Destroy();
		}
		
		private void newProject(object source, EventArgs args)
		{
		  Project p = new Project(); 
		  ProjectWindow pw = new ProjectWindow(p);
		  pw.Show();
		  
		  this.projects.Add(p);
		}

	}

}