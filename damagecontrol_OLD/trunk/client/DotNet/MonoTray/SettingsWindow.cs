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
	    private DamageControlTrayIcon icon;
	    
		[Widget] Button closeSettingsButton;
		[Widget] Button newButton;
		[Widget] Window settingsWindow;
		[Widget] TreeView projectsTreeview;
		[Widget] Button deleteButton;
		[Widget] Button propertiesButton;
		[Widget] Button testButton;
		private TreeStore store;
		private TreeIter iter;
		
		public SettingsWindow (ArrayList p, DamageControlTrayIcon i)
		{
			Glade.XML gxml = new Glade.XML (null, "gui.glade", "settingsWindow", null);
			gxml.Autoconnect (this);
			
			this.projects = p;
			this.icon = i;
			
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
			this.deleteButton.Clicked += deleteProject;
			this.propertiesButton.Clicked += editProperties;
			this.testButton.Clicked += testConnection;
			
			
			//TreeView            
            
            TreeViewColumn NameCol = new TreeViewColumn ();
            CellRenderer NameRenderer = new CellRendererText ();
            NameCol.Title = "Project Name";
            NameCol.PackStart (NameRenderer, true);
            NameCol.AddAttribute (NameRenderer, "text", 0);
            


            TreeViewColumn StatusCol = new TreeViewColumn ();
            CellRenderer StatusRenderer = new CellRendererPixbuf ();
            StatusRenderer.Xalign = 1.0F;
            StatusCol.Title = "Status";
            StatusCol.PackEnd (StatusRenderer, true);
            StatusCol.AddAttribute (StatusRenderer, "pixbuf", 1);
            
            NameCol.PackStart (StatusRenderer, true);
            NameCol.AddAttribute (StatusRenderer, "pixbuf", 1);
            
            projectsTreeview.AppendColumn (NameCol);
            //projectsTreeview.AppendColumn (StatusCol);
            
            projectsTreeview.HeadersVisible = true;
            
            
            store = new TreeStore (new GLib.GType[] {GLib.GType.String, GLib.GType.Object, GLib.GType.Int});
            
            
            iter = new TreeIter();
            
            this.projectsTreeview.Model = store;
            
            UpdateProjectList();
            
            foreach (Project proj in this.projects)
                proj.OnPolled += new PolledEventHandler(ProjectPolled);
		}
		
		private void UpdateProjectList()
		{
		  store.Clear();
		  foreach (Project p in this.projects)
		  {
		        GLib.Value Name = new GLib.Value (p.Projectname);
                Gdk.Pixbuf buf;
                if (p.ProjectStatus.BuildStatus == BuildStatus.Success)
                {
                    Console.WriteLine("OK");
                    buf = new Gdk.Pixbuf(null, "green-24.png");
                }
                else if (p.ProjectStatus.BuildStatus == BuildStatus.Failure)
                {   
                    Console.WriteLine("Failed");
                    buf = new Gdk.Pixbuf(null, "red-24.png");
                }
                else
                {
                    Console.WriteLine("Unknown");
                    buf = new Gdk.Pixbuf(null, "gray-24.png");
                }
                store.Append (out iter);
                store.SetValue (iter, 0, Name);
                store.SetValue (iter, 1, buf);
                store.SetValue (iter, 2, this.projects.IndexOf(p));
		  }
		  MonoTray.SaveProjects(this.projects);
		  
		  this.projectsTreeview.ShowAll();
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
		
		private void deleteProject(object sauce, EventArgs args)
		{
		  TreeIter i;
		  TreeModel m;
		  if (projectsTreeview.Selection.GetSelected(out m, out i))
		  {
		      int val = (int) m.GetValue (i, 2);
		      this.projects.RemoveAt(val);
		      UpdateProjectList();
		  }
		}
		
		
		private void testConnection(object sauce, EventArgs args)
		{
		  TreeIter i;
		  TreeModel m;
		  if (projectsTreeview.Selection.GetSelected(out m, out i))
		  {
		      int val = (int) m.GetValue (i, 2);
		      Project p = (Project) this.projects.ToArray()[val];
		      string errormessage = p.TestConnection();
			  if (errormessage==null) 
			  {
				  ConnectionDialog cd = new ConnectionDialog("Connection OK", "All connection settings are OK.");
			  }
			  else
			  {
				  ConnectionDialog cd = new ConnectionDialog("Connection failed", "Could not establish connection: " + errormessage);
			  }
		      
		  }
		}
		
		private void editProperties(object sauce, EventArgs args)
		{
		  TreeIter i;
		  TreeModel m;
		  if (projectsTreeview.Selection.GetSelected(out m, out i))
		  {
		      int val = (int) m.GetValue (i, 2);
		      Project p = (Project) this.projects.ToArray()[val];
		      ProjectWindow pw = new ProjectWindow(p);
		      pw.OnProjectChanged += ProjectWindowHidden;
		      pw.Show();
		  }
		}
		
		
		
		private void newProject(object source, EventArgs args)
		{
		  Project p = new Project();
		  p.StartPolling(); 
		  ProjectWindow pw = new ProjectWindow(p);
		  pw.OnProjectChanged += ProjectWindowHidden;
		  p.OnPolled += new PolledEventHandler(ProjectPolled);
		  p.OnPolled += new PolledEventHandler(this.icon.ProjectPolled);
		  
		  p.OnBuildOccurred += new BuildOccurredEventHandler(this.icon.BuildOccurred);
		  
		  
		  pw.Show();
		  
		  this.projects.Add(p);
		  UpdateProjectList();
		}
		
		private void ProjectPolled(object source, PolledEventArgs args)
		{
		  UpdateProjectList();
		}
		
		private void ProjectWindowHidden(object sauce, EventArgs args)
		{
		  UpdateProjectList();
		}

	}

}