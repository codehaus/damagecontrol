using System;
using Gtk;
using GtkSharp;
using Glade;
using GLib;
using ThoughtWorks.DamageControl.DamageControlClientNet;

namespace ThoughtWorks.DamageControl.MonoTray {

	public class ProjectWindow 
	{
	   public event EventHandler OnProjectChanged;
	   
	   private Project project;
	   [Widget] public Window projectWindow;
	   [Widget] Button closeProjectButton;
	   [Widget] Entry projectnameEntry;
	   [Widget] Entry urlEntry;
	   [Widget] CheckButton httpauthCheckbox;
	   [Widget] Entry usernameEntry;
	   [Widget] Entry passwordEntry;
	   [Widget] SpinButton pollingEntry;
	   
	   private void ProjectChanged()
	   {
	       if (this.OnProjectChanged!=null) 
		   {
		      OnProjectChanged(this.project, new EventArgs());
		   } 
	   }
	   
	   public ProjectWindow():this(new Project())
	   {
	   }
	   
	   public Project Project
	   {
	       get
	       {
	           return this.project;
	       }
	   }
	   
	   public ProjectWindow(Project p)
       {
            Glade.XML gxml = new Glade.XML (null, "gui.glade", "projectWindow", null);
            gxml.Autoconnect (this);
            this.project = p;
            p.StopPolling();
            
            if ((this.project.Projectname==null))
                this.projectnameEntry.Text = "";
            else
                this.projectnameEntry.Text = this.project.Projectname;
            if ((this.project.InstallationUrl==null))
                this.urlEntry.Text = "";
            else    
                this.urlEntry.Text = this.project.InstallationUrl;
            
            
            this.pollingEntry.Value = this.project.Interval;
            
            
            
            Console.WriteLine("populating password field");
            
            if ((this.project.Username!=null)&&(this.project.Password!=null))
            {
                this.httpauthCheckbox.Active = true;
                this.usernameEntry.Editable = true;
                this.passwordEntry.Editable = true;
                this.usernameEntry.Sensitive = true;
                this.passwordEntry.Sensitive = true;
                this.usernameEntry.Text = this.project.Username;
                this.passwordEntry.Text = this.project.Password;
            }
            else
            {
                this.httpauthCheckbox.Active = false;
                this.usernameEntry.Editable = false;
                this.passwordEntry.Editable = false;
                this.usernameEntry.Sensitive = false;
                this.passwordEntry.Sensitive = false;
                this.usernameEntry.Text = "";
                this.passwordEntry.Text = "";
            }
            
            
            this.projectnameEntry.Changed += updateProjectname;
            this.urlEntry.Changed += updateUrl;
            this.pollingEntry.Changed += updatePolling;
            this.httpauthCheckbox.Toggled += updateAuthentification;
            this.usernameEntry.Changed += updateAuthentification;
            this.passwordEntry.Changed += updateAuthentification;
            
            
            this.closeProjectButton.Clicked += hideWindow;
	   }
	   
	   private void hideWindow(object source, EventArgs args)
	   {
	       this.projectWindow.Hide();
	       this.project.StartPolling();
	       ProjectChanged();
	   }
	   
	   private void updateAuthentification(object o, StateChangedArgs s)
	   {
	       updateAuthentification();
	       ProjectChanged();
	   }
	   
	   private void updateAuthentification(object o, EventArgs a)
	   {
	       updateAuthentification();
	       ProjectChanged();
	   }
	   
	   
	   private void updateAuthentification()
	   {
	       Console.WriteLine("authenti");
	       if (this.httpauthCheckbox.Active == true)
	       {
	           this.usernameEntry.Editable = true;
               this.passwordEntry.Editable = true;
               this.usernameEntry.Sensitive = true;
               this.passwordEntry.Sensitive = true;
               
               this.project.Username = usernameEntry.Text;
               this.project.Password = passwordEntry.Text;
	       }
	       else
	       {
	           this.usernameEntry.Editable = false;
               this.passwordEntry.Editable = false;
               this.usernameEntry.Sensitive = false;
               this.passwordEntry.Sensitive = false;
               this.usernameEntry.Text = "";
               this.passwordEntry.Text = "";
               
               this.project.Username = null;
               this.project.Password = null;
	       }
	   }
	   
	   private void updatePolling(object source, EventArgs args)
	   {
	       this.project.Interval = (int) this.pollingEntry.Value;
	       ProjectChanged();
	   }
	   
	   private void updateProjectname(object source, EventArgs args)
	   {
	       this.project.Projectname = this.projectnameEntry.Text;
	       ProjectChanged();
	   }
	   
	   private void updateUrl(object source, EventArgs args)
	   {
	       this.project.InstallationUrl = this.urlEntry.Text;
	       ProjectChanged();
	   }
	   
	   public void Show()
	   {
	       projectWindow.Show();
	   }
	   
	   
	}
}