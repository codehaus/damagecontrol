// created on 11/6/2004 at 3:29 PM
using System;
using ThoughtWorks.DamageControl.MonoTray;
using Gtk;
using Glade;

namespace ThoughtWorks.DamageControl.MonoTray {

	public class SettingsWindow
	{
		[Widget] Button closeSettingsButton;
		[Widget] Button newButton;
		[Widget] Window settingsWindow;
		
		public SettingsWindow ()
		{
			Glade.XML gxml = new Glade.XML (null, "gui.glade", "settingsWindow", null);
			gxml.Autoconnect (this);
			
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
			Application.Quit ();
			args.RetVal = true;
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
		  ProjectWindow pw = new ProjectWindow();
		  pw.Show();
		}

	}

}