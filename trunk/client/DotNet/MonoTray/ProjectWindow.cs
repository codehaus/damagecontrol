using System;
using Gtk;
using Glade;

namespace ThoughtWorks.DamageControl.MonoTray {

	public class ProjectWindow 
	{
	   [Widget] Window projectWindow;
	   [Widget] Button closeProjectButton;
	   public ProjectWindow()
       {
            Glade.XML gxml = new Glade.XML (null, "gui.glade", "projectWindow", null);
            gxml.Autoconnect (this);
            
            this.closeProjectButton.Clicked += hideWindow;
	   }
	   
	   private void hideWindow(object source, EventArgs args)
	   {
	       this.projectWindow.Hide();
	   }
	   
	   public void Show()
	   {
	       projectWindow.Show();
	   }
	}
}