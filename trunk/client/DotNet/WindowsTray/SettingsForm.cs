using System;
using System.IO;
using System.Diagnostics;
using System.Windows.Forms;
using System.Collections;
using DamageControlClientNet;
using Nwc.XmlRpc;
using ThoughtWorks.DamageControl.DamageControlClientNet;

namespace ThoughtWorks.DamageControl.WindowsTray
{
	/// <summary>
	/// Displays user settings for the DamageControl monitor, allowing
	/// changes to be made.
	/// </summary>
	public class SettingsForm : Form, ProjectVisitor
	{
		#region Gui control declarations

		CheckBox chkAudioSuccessful;
		CheckBox chkAudioBroken;
		CheckBox chkAudioFixed;
		CheckBox chkAudioStillFailing;
		TextBox txtAudioFileSuccess;
		TextBox txtAudioFileFixed;
		TextBox txtAudioFileBroken;
		TextBox txtAudioFileFailing;
		Button btnFindAudioSuccess;
		Button btnFindAudioFixed;
		Button btnFindAudioBroken;
		Button btnFindAudioFailing;
		Button btnPlayBroken;
		Button btnPlayFailing;
		Button btnPlayFixed;
		Button btnPlaySuccess;
		OpenFileDialog dlgOpenFile;

		#endregion

		Settings _settings;
		private System.Windows.Forms.Button okButton;
		private System.Windows.Forms.Button cancelButton;
		private System.Windows.Forms.ListView projectListView;
		private System.Windows.Forms.Button addProjectButton;
		private System.Windows.Forms.Button removeProjectButton;
		private System.Windows.Forms.Button testConnectionButton;
		private System.Windows.Forms.Button proxyConfigurationButton;
		private System.Windows.Forms.ColumnHeader projectName;
		private System.Windows.Forms.ColumnHeader projectStatus;
		private System.Windows.Forms.ImageList smallImageList;
		private System.Windows.Forms.ImageList largeImageList;
		private System.Windows.Forms.ContextMenu projectListContextMenu;
		private System.Windows.Forms.MenuItem propertiesMenuItem;
		private System.Windows.Forms.MenuItem removeMenuItem;
		private System.Windows.Forms.Button propertyButton;
		private System.Windows.Forms.GroupBox grpGlobal;
		private System.Windows.Forms.CheckBox balloonCheckBox;

		private SystemTrayMonitor monitor;

		#region Constructors

		public SettingsForm(Settings settings, SystemTrayMonitor m)
		{
			_settings = settings;
			settings.accept(this);
			this.monitor = m;

			InitializeComponent();
			ExtraInitialisation();
		}

		/// <summary>
		/// This constructor is for designer use only.
		/// </summary>
		public SettingsForm()
		{
			InitializeComponent();
			ExtraInitialisation();
		}

		void ExtraInitialisation()
		{
			dlgOpenFile.InitialDirectory = AppDomain.CurrentDomain.BaseDirectory;
			this.balloonCheckBox.Checked = _settings.NotificationBalloon.ShowBalloon;
			UpdateProjectList();
			
		}

		private void UpdateProjectList()
		{
			this.projectListView.Items.Clear();
			foreach (MenuItem m in this.monitor.ContextMenu.MenuItems)
			{
				if (m is ProjectMenuItem)
					this.monitor.ContextMenu.MenuItems.Remove(m);
			}
			foreach (Project p in this._settings.Projects)
			{
				int imageindex = 0;
				if (p.ProjectStatus.BuildStatus.Equals(BuildStatus.Successful))
				{
					imageindex = 1;
				} 
				else if (p.ProjectStatus.BuildStatus.Equals(BuildStatus.Failed)) 
				{
					imageindex = 2;
				}
				ProjectMenuItem projectMenuItem = new ProjectMenuItem(p);
				this.monitor.ContextMenu.MenuItems.Add(0, projectMenuItem);
				ListViewItem item = new ListViewItem(p.Projectname, imageindex);
				this.projectListView.Items.Add(item);
			}
		}

		#endregion

		private System.ComponentModel.IContainer components;

		#region Windows Form Designer generated code


		/// <summary>
		/// Clean up any resources being used.
		/// </summary>
		protected override void Dispose(bool disposing)
		{
			if (disposing)
			{
				if (components != null)
				{
					components.Dispose();
				}
			}
			base.Dispose(disposing);
		}

		/// <summary>
		/// Required method for Designer support - do not modify
		/// the contents of this method with the code editor.
		/// </summary>
		private void InitializeComponent()
		{
			this.components = new System.ComponentModel.Container();
			System.Resources.ResourceManager resources = new System.Resources.ResourceManager(typeof(SettingsForm));
			this.grpGlobal = new System.Windows.Forms.GroupBox();
			this.btnFindAudioSuccess = new System.Windows.Forms.Button();
			this.txtAudioFileSuccess = new System.Windows.Forms.TextBox();
			this.chkAudioSuccessful = new System.Windows.Forms.CheckBox();
			this.chkAudioBroken = new System.Windows.Forms.CheckBox();
			this.chkAudioFixed = new System.Windows.Forms.CheckBox();
			this.chkAudioStillFailing = new System.Windows.Forms.CheckBox();
			this.txtAudioFileFixed = new System.Windows.Forms.TextBox();
			this.txtAudioFileBroken = new System.Windows.Forms.TextBox();
			this.txtAudioFileFailing = new System.Windows.Forms.TextBox();
			this.btnFindAudioFixed = new System.Windows.Forms.Button();
			this.btnFindAudioBroken = new System.Windows.Forms.Button();
			this.btnFindAudioFailing = new System.Windows.Forms.Button();
			this.btnPlayBroken = new System.Windows.Forms.Button();
			this.btnPlayFailing = new System.Windows.Forms.Button();
			this.btnPlayFixed = new System.Windows.Forms.Button();
			this.btnPlaySuccess = new System.Windows.Forms.Button();
			this.dlgOpenFile = new System.Windows.Forms.OpenFileDialog();
			this.okButton = new System.Windows.Forms.Button();
			this.cancelButton = new System.Windows.Forms.Button();
			this.projectListView = new System.Windows.Forms.ListView();
			this.addProjectButton = new System.Windows.Forms.Button();
			this.removeProjectButton = new System.Windows.Forms.Button();
			this.testConnectionButton = new System.Windows.Forms.Button();
			this.proxyConfigurationButton = new System.Windows.Forms.Button();
			this.projectName = new System.Windows.Forms.ColumnHeader();
			this.projectStatus = new System.Windows.Forms.ColumnHeader();
			this.smallImageList = new System.Windows.Forms.ImageList(this.components);
			this.largeImageList = new System.Windows.Forms.ImageList(this.components);
			this.projectListContextMenu = new System.Windows.Forms.ContextMenu();
			this.propertiesMenuItem = new System.Windows.Forms.MenuItem();
			this.removeMenuItem = new System.Windows.Forms.MenuItem();
			this.propertyButton = new System.Windows.Forms.Button();
			this.balloonCheckBox = new System.Windows.Forms.CheckBox();
			this.grpGlobal.SuspendLayout();
			this.SuspendLayout();
			// 
			// grpGlobal
			// 
			this.grpGlobal.Controls.Add(this.balloonCheckBox);
			this.grpGlobal.Controls.Add(this.btnFindAudioSuccess);
			this.grpGlobal.Controls.Add(this.txtAudioFileSuccess);
			this.grpGlobal.Controls.Add(this.chkAudioSuccessful);
			this.grpGlobal.Controls.Add(this.chkAudioBroken);
			this.grpGlobal.Controls.Add(this.chkAudioFixed);
			this.grpGlobal.Controls.Add(this.chkAudioStillFailing);
			this.grpGlobal.Controls.Add(this.txtAudioFileFixed);
			this.grpGlobal.Controls.Add(this.txtAudioFileBroken);
			this.grpGlobal.Controls.Add(this.txtAudioFileFailing);
			this.grpGlobal.Controls.Add(this.btnFindAudioFixed);
			this.grpGlobal.Controls.Add(this.btnFindAudioBroken);
			this.grpGlobal.Controls.Add(this.btnFindAudioFailing);
			this.grpGlobal.Controls.Add(this.btnPlayBroken);
			this.grpGlobal.Controls.Add(this.btnPlayFailing);
			this.grpGlobal.Controls.Add(this.btnPlayFixed);
			this.grpGlobal.Controls.Add(this.btnPlaySuccess);
			this.grpGlobal.FlatStyle = System.Windows.Forms.FlatStyle.System;
			this.grpGlobal.Location = new System.Drawing.Point(8, 248);
			this.grpGlobal.Name = "grpGlobal";
			this.grpGlobal.Size = new System.Drawing.Size(368, 152);
			this.grpGlobal.TabIndex = 4;
			this.grpGlobal.TabStop = false;
			this.grpGlobal.Text = "Notification Settings";
			// 
			// btnFindAudioSuccess
			// 
			this.btnFindAudioSuccess.Image = ((System.Drawing.Image)(resources.GetObject("btnFindAudioSuccess.Image")));
			this.btnFindAudioSuccess.ImageAlign = System.Drawing.ContentAlignment.MiddleRight;
			this.btnFindAudioSuccess.Location = new System.Drawing.Point(304, 56);
			this.btnFindAudioSuccess.Name = "btnFindAudioSuccess";
			this.btnFindAudioSuccess.Size = new System.Drawing.Size(22, 20);
			this.btnFindAudioSuccess.TabIndex = 2;
			this.btnFindAudioSuccess.Click += new System.EventHandler(this.btnFindAudioSuccess_Click);
			// 
			// txtAudioFileSuccess
			// 
			this.txtAudioFileSuccess.Location = new System.Drawing.Point(112, 56);
			this.txtAudioFileSuccess.Name = "txtAudioFileSuccess";
			this.txtAudioFileSuccess.Size = new System.Drawing.Size(184, 21);
			this.txtAudioFileSuccess.TabIndex = 1;
			this.txtAudioFileSuccess.Text = "";
			// 
			// chkAudioSuccessful
			// 
			this.chkAudioSuccessful.FlatStyle = System.Windows.Forms.FlatStyle.System;
			this.chkAudioSuccessful.Location = new System.Drawing.Point(16, 56);
			this.chkAudioSuccessful.Name = "chkAudioSuccessful";
			this.chkAudioSuccessful.Size = new System.Drawing.Size(96, 16);
			this.chkAudioSuccessful.TabIndex = 0;
			this.chkAudioSuccessful.Text = "Successful";
			// 
			// chkAudioBroken
			// 
			this.chkAudioBroken.FlatStyle = System.Windows.Forms.FlatStyle.System;
			this.chkAudioBroken.Font = new System.Drawing.Font("Verdana", 8.25F);
			this.chkAudioBroken.Location = new System.Drawing.Point(16, 104);
			this.chkAudioBroken.Name = "chkAudioBroken";
			this.chkAudioBroken.Size = new System.Drawing.Size(96, 16);
			this.chkAudioBroken.TabIndex = 0;
			this.chkAudioBroken.Text = "Broken";
			// 
			// chkAudioFixed
			// 
			this.chkAudioFixed.FlatStyle = System.Windows.Forms.FlatStyle.System;
			this.chkAudioFixed.Font = new System.Drawing.Font("Verdana", 8.25F);
			this.chkAudioFixed.Location = new System.Drawing.Point(16, 80);
			this.chkAudioFixed.Name = "chkAudioFixed";
			this.chkAudioFixed.Size = new System.Drawing.Size(96, 16);
			this.chkAudioFixed.TabIndex = 0;
			this.chkAudioFixed.Text = "Fixed";
			// 
			// chkAudioStillFailing
			// 
			this.chkAudioStillFailing.FlatStyle = System.Windows.Forms.FlatStyle.System;
			this.chkAudioStillFailing.Font = new System.Drawing.Font("Verdana", 8.25F);
			this.chkAudioStillFailing.Location = new System.Drawing.Point(16, 128);
			this.chkAudioStillFailing.Name = "chkAudioStillFailing";
			this.chkAudioStillFailing.Size = new System.Drawing.Size(96, 16);
			this.chkAudioStillFailing.TabIndex = 0;
			this.chkAudioStillFailing.Text = "Still failing";
			// 
			// txtAudioFileFixed
			// 
			this.txtAudioFileFixed.Font = new System.Drawing.Font("Verdana", 8.25F);
			this.txtAudioFileFixed.Location = new System.Drawing.Point(112, 80);
			this.txtAudioFileFixed.Name = "txtAudioFileFixed";
			this.txtAudioFileFixed.Size = new System.Drawing.Size(184, 21);
			this.txtAudioFileFixed.TabIndex = 1;
			this.txtAudioFileFixed.Text = "";
			// 
			// txtAudioFileBroken
			// 
			this.txtAudioFileBroken.Font = new System.Drawing.Font("Verdana", 8.25F);
			this.txtAudioFileBroken.Location = new System.Drawing.Point(112, 104);
			this.txtAudioFileBroken.Name = "txtAudioFileBroken";
			this.txtAudioFileBroken.Size = new System.Drawing.Size(184, 21);
			this.txtAudioFileBroken.TabIndex = 1;
			this.txtAudioFileBroken.Text = "";
			// 
			// txtAudioFileFailing
			// 
			this.txtAudioFileFailing.Font = new System.Drawing.Font("Verdana", 8.25F);
			this.txtAudioFileFailing.Location = new System.Drawing.Point(112, 128);
			this.txtAudioFileFailing.Name = "txtAudioFileFailing";
			this.txtAudioFileFailing.Size = new System.Drawing.Size(184, 21);
			this.txtAudioFileFailing.TabIndex = 1;
			this.txtAudioFileFailing.Text = "";
			// 
			// btnFindAudioFixed
			// 
			this.btnFindAudioFixed.Image = ((System.Drawing.Image)(resources.GetObject("btnFindAudioFixed.Image")));
			this.btnFindAudioFixed.ImageAlign = System.Drawing.ContentAlignment.MiddleRight;
			this.btnFindAudioFixed.Location = new System.Drawing.Point(304, 80);
			this.btnFindAudioFixed.Name = "btnFindAudioFixed";
			this.btnFindAudioFixed.Size = new System.Drawing.Size(22, 20);
			this.btnFindAudioFixed.TabIndex = 2;
			this.btnFindAudioFixed.Click += new System.EventHandler(this.btnFindAudioFixed_Click);
			// 
			// btnFindAudioBroken
			// 
			this.btnFindAudioBroken.Image = ((System.Drawing.Image)(resources.GetObject("btnFindAudioBroken.Image")));
			this.btnFindAudioBroken.ImageAlign = System.Drawing.ContentAlignment.MiddleRight;
			this.btnFindAudioBroken.Location = new System.Drawing.Point(304, 104);
			this.btnFindAudioBroken.Name = "btnFindAudioBroken";
			this.btnFindAudioBroken.Size = new System.Drawing.Size(22, 20);
			this.btnFindAudioBroken.TabIndex = 2;
			this.btnFindAudioBroken.Click += new System.EventHandler(this.btnFindAudioBroken_Click);
			// 
			// btnFindAudioFailing
			// 
			this.btnFindAudioFailing.Image = ((System.Drawing.Image)(resources.GetObject("btnFindAudioFailing.Image")));
			this.btnFindAudioFailing.ImageAlign = System.Drawing.ContentAlignment.MiddleRight;
			this.btnFindAudioFailing.Location = new System.Drawing.Point(304, 128);
			this.btnFindAudioFailing.Name = "btnFindAudioFailing";
			this.btnFindAudioFailing.Size = new System.Drawing.Size(22, 20);
			this.btnFindAudioFailing.TabIndex = 2;
			this.btnFindAudioFailing.Click += new System.EventHandler(this.btnFindAudioFailing_Click);
			// 
			// btnPlayBroken
			// 
			this.btnPlayBroken.Image = ((System.Drawing.Image)(resources.GetObject("btnPlayBroken.Image")));
			this.btnPlayBroken.Location = new System.Drawing.Point(328, 104);
			this.btnPlayBroken.Name = "btnPlayBroken";
			this.btnPlayBroken.Size = new System.Drawing.Size(22, 20);
			this.btnPlayBroken.TabIndex = 2;
			this.btnPlayBroken.Click += new System.EventHandler(this.btnPlayBroken_Click);
			// 
			// btnPlayFailing
			// 
			this.btnPlayFailing.Image = ((System.Drawing.Image)(resources.GetObject("btnPlayFailing.Image")));
			this.btnPlayFailing.Location = new System.Drawing.Point(328, 128);
			this.btnPlayFailing.Name = "btnPlayFailing";
			this.btnPlayFailing.Size = new System.Drawing.Size(22, 20);
			this.btnPlayFailing.TabIndex = 2;
			this.btnPlayFailing.Click += new System.EventHandler(this.btnPlayFailing_Click);
			// 
			// btnPlayFixed
			// 
			this.btnPlayFixed.Image = ((System.Drawing.Image)(resources.GetObject("btnPlayFixed.Image")));
			this.btnPlayFixed.Location = new System.Drawing.Point(328, 80);
			this.btnPlayFixed.Name = "btnPlayFixed";
			this.btnPlayFixed.Size = new System.Drawing.Size(22, 20);
			this.btnPlayFixed.TabIndex = 2;
			this.btnPlayFixed.Click += new System.EventHandler(this.btnPlayFixed_Click);
			// 
			// btnPlaySuccess
			// 
			this.btnPlaySuccess.Image = ((System.Drawing.Image)(resources.GetObject("btnPlaySuccess.Image")));
			this.btnPlaySuccess.Location = new System.Drawing.Point(328, 56);
			this.btnPlaySuccess.Name = "btnPlaySuccess";
			this.btnPlaySuccess.Size = new System.Drawing.Size(22, 20);
			this.btnPlaySuccess.TabIndex = 2;
			this.btnPlaySuccess.Click += new System.EventHandler(this.btnPlaySuccess_Click);
			// 
			// dlgOpenFile
			// 
			this.dlgOpenFile.DefaultExt = "*.wav";
			this.dlgOpenFile.Title = "Select wave file";
			// 
			// okButton
			// 
			this.okButton.Location = new System.Drawing.Point(216, 408);
			this.okButton.Name = "okButton";
			this.okButton.TabIndex = 5;
			this.okButton.Text = "OK";
			this.okButton.Click += new System.EventHandler(this.btnOkay_Click);
			// 
			// cancelButton
			// 
			this.cancelButton.DialogResult = System.Windows.Forms.DialogResult.Cancel;
			this.cancelButton.Location = new System.Drawing.Point(296, 408);
			this.cancelButton.Name = "cancelButton";
			this.cancelButton.TabIndex = 6;
			this.cancelButton.Text = "Cancel";
			this.cancelButton.Click += new System.EventHandler(this.btnCancel_Click);
			// 
			// projectListView
			// 
			this.projectListView.Columns.AddRange(new System.Windows.Forms.ColumnHeader[] {
																							  this.projectName,
																							  this.projectStatus});
			this.projectListView.ContextMenu = this.projectListContextMenu;
			this.projectListView.LargeImageList = this.largeImageList;
			this.projectListView.Location = new System.Drawing.Point(8, 16);
			this.projectListView.MultiSelect = false;
			this.projectListView.Name = "projectListView";
			this.projectListView.Size = new System.Drawing.Size(288, 216);
			this.projectListView.SmallImageList = this.smallImageList;
			this.projectListView.TabIndex = 7;
			// 
			// addProjectButton
			// 
			this.addProjectButton.Location = new System.Drawing.Point(304, 16);
			this.addProjectButton.Name = "addProjectButton";
			this.addProjectButton.TabIndex = 8;
			this.addProjectButton.Text = "Add...";
			this.addProjectButton.Click += new System.EventHandler(this.addProjectButton_Click);
			// 
			// removeProjectButton
			// 
			this.removeProjectButton.Location = new System.Drawing.Point(304, 48);
			this.removeProjectButton.Name = "removeProjectButton";
			this.removeProjectButton.TabIndex = 9;
			this.removeProjectButton.Text = "Remove";
			this.removeProjectButton.Click += new System.EventHandler(this.removeProjectButton_Click);
			// 
			// testConnectionButton
			// 
			this.testConnectionButton.Location = new System.Drawing.Point(304, 112);
			this.testConnectionButton.Name = "testConnectionButton";
			this.testConnectionButton.TabIndex = 10;
			this.testConnectionButton.Text = "Test";
			// 
			// proxyConfigurationButton
			// 
			this.proxyConfigurationButton.Location = new System.Drawing.Point(304, 208);
			this.proxyConfigurationButton.Name = "proxyConfigurationButton";
			this.proxyConfigurationButton.TabIndex = 11;
			this.proxyConfigurationButton.Text = "Proxy...";
			this.proxyConfigurationButton.Click += new System.EventHandler(this.proxyConfigurationButton_Click);
			// 
			// projectName
			// 
			this.projectName.Text = "Project Name";
			// 
			// projectStatus
			// 
			this.projectStatus.Text = "Status";
			// 
			// smallImageList
			// 
			this.smallImageList.ImageSize = new System.Drawing.Size(16, 16);
			this.smallImageList.ImageStream = ((System.Windows.Forms.ImageListStreamer)(resources.GetObject("smallImageList.ImageStream")));
			this.smallImageList.TransparentColor = System.Drawing.Color.Transparent;
			// 
			// largeImageList
			// 
			this.largeImageList.ImageSize = new System.Drawing.Size(32, 32);
			this.largeImageList.ImageStream = ((System.Windows.Forms.ImageListStreamer)(resources.GetObject("largeImageList.ImageStream")));
			this.largeImageList.TransparentColor = System.Drawing.Color.Transparent;
			// 
			// projectListContextMenu
			// 
			this.projectListContextMenu.MenuItems.AddRange(new System.Windows.Forms.MenuItem[] {
																								   this.propertiesMenuItem,
																								   this.removeMenuItem});
			// 
			// propertiesMenuItem
			// 
			this.propertiesMenuItem.Index = 0;
			this.propertiesMenuItem.Text = "Properties...";
			this.propertiesMenuItem.Click += new System.EventHandler(this.propertiesMenuItem_Click);
			// 
			// removeMenuItem
			// 
			this.removeMenuItem.Index = 1;
			this.removeMenuItem.Text = "Remove";
			this.removeMenuItem.Click += new System.EventHandler(this.removeMenuItem_Click);
			// 
			// propertyButton
			// 
			this.propertyButton.Location = new System.Drawing.Point(304, 80);
			this.propertyButton.Name = "propertyButton";
			this.propertyButton.TabIndex = 12;
			this.propertyButton.Text = "Properties...";
			this.propertyButton.Click += new System.EventHandler(this.propertiesMenuItem_Click);
			// 
			// balloonCheckBox
			// 
			this.balloonCheckBox.Checked = true;
			this.balloonCheckBox.CheckState = System.Windows.Forms.CheckState.Checked;
			this.balloonCheckBox.Location = new System.Drawing.Point(16, 24);
			this.balloonCheckBox.Name = "balloonCheckBox";
			this.balloonCheckBox.Size = new System.Drawing.Size(328, 24);
			this.balloonCheckBox.TabIndex = 3;
			this.balloonCheckBox.Text = "use balloon notifications";
			// 
			// SettingsForm
			// 
			this.AcceptButton = this.okButton;
			this.AutoScaleBaseSize = new System.Drawing.Size(5, 14);
			this.CancelButton = this.cancelButton;
			this.ClientSize = new System.Drawing.Size(386, 442);
			this.ControlBox = false;
			this.Controls.Add(this.propertyButton);
			this.Controls.Add(this.proxyConfigurationButton);
			this.Controls.Add(this.testConnectionButton);
			this.Controls.Add(this.removeProjectButton);
			this.Controls.Add(this.addProjectButton);
			this.Controls.Add(this.projectListView);
			this.Controls.Add(this.cancelButton);
			this.Controls.Add(this.okButton);
			this.Controls.Add(this.grpGlobal);
			this.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedToolWindow;
			this.Icon = ((System.Drawing.Icon)(resources.GetObject("$this.Icon")));
			this.MaximizeBox = false;
			this.MinimizeBox = false;
			this.Name = "SettingsForm";
			this.ShowInTaskbar = false;
			this.SizeGripStyle = System.Windows.Forms.SizeGripStyle.Hide;
			this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
			this.Text = "DamageControl Monitor Settings";
			this.Load += new System.EventHandler(this.SettingsForm_Load);
			this.grpGlobal.ResumeLayout(false);
			this.ResumeLayout(false);

		}

		#endregion

		public void Launch()
		{
			Application.EnableVisualStyles();
			PopulateControlsFromSettings();
			this.Show();
		}


		#region Moving settings between Settings object and Gui controls

		/// <summary>
		/// Copies values from the 
		/// </summary>
		void PopulateControlsFromSettings()
		{


			chkAudioBroken.Checked = _settings.Sounds.BrokenBuildSound.Play;
			chkAudioFixed.Checked = _settings.Sounds.FixedBuildSound.Play;
			chkAudioStillFailing.Checked = _settings.Sounds.AnotherFailedBuildSound.Play;
			chkAudioSuccessful.Checked = _settings.Sounds.AnotherSuccessfulBuildSound.Play;

			txtAudioFileBroken.Text = _settings.Sounds.BrokenBuildSound.FileName;
			txtAudioFileFixed.Text = _settings.Sounds.FixedBuildSound.FileName;
			txtAudioFileFailing.Text = _settings.Sounds.AnotherFailedBuildSound.FileName;
			txtAudioFileSuccess.Text = _settings.Sounds.AnotherSuccessfulBuildSound.FileName;
		}

		void PopulateSettingsFromControls()
		{

			_settings.NotificationBalloon.ShowBalloon = this.balloonCheckBox.Checked;
			_settings.Sounds.BrokenBuildSound.Play = chkAudioBroken.Checked;
			_settings.Sounds.FixedBuildSound.Play = chkAudioFixed.Checked;
			_settings.Sounds.AnotherFailedBuildSound.Play = chkAudioStillFailing.Checked;
			_settings.Sounds.AnotherSuccessfulBuildSound.Play = chkAudioSuccessful.Checked;

			_settings.Sounds.BrokenBuildSound.FileName = txtAudioFileBroken.Text;
			_settings.Sounds.FixedBuildSound.FileName = txtAudioFileFixed.Text;
			_settings.Sounds.AnotherFailedBuildSound.FileName = txtAudioFileFailing.Text;
			_settings.Sounds.AnotherSuccessfulBuildSound.FileName = txtAudioFileSuccess.Text;

			SettingsManager.WriteSettings(this._settings);
		}

		#endregion

		#region Ok & Cancel

		void btnOkay_Click(object sender, System.EventArgs e)
		{
			PopulateSettingsFromControls();
			
			// save settings

			this.Hide();

			// force a poll once the form is hidden
		}

		private void btnCancel_Click(object sender, System.EventArgs e)
		{
			this.Hide();
			PopulateControlsFromSettings();
		}

		#endregion

		#region Finding audio files

		private void btnFindAudioSuccess_Click(object sender, System.EventArgs e)
		{
			FindAudioFile(txtAudioFileSuccess);
		}

		private void btnFindAudioFixed_Click(object sender, System.EventArgs e)
		{
			FindAudioFile(txtAudioFileFixed);
		}

		private void btnFindAudioBroken_Click(object sender, System.EventArgs e)
		{
			FindAudioFile(txtAudioFileBroken);
		}

		private void btnFindAudioFailing_Click(object sender, System.EventArgs e)
		{
			FindAudioFile(txtAudioFileFailing);
		}

		void FindAudioFile(TextBox textBox)
		{
			DialogResult result = dlgOpenFile.ShowDialog();

			if (result!=DialogResult.OK)
				return;
			
			string fileName = dlgOpenFile.FileName;

			// make relative path
			if (fileName.StartsWith(AppDomain.CurrentDomain.BaseDirectory))
				fileName = fileName.Substring(AppDomain.CurrentDomain.BaseDirectory.Length);

			textBox.Text = fileName;
		}

		#endregion

		#region Previewing audio

		private void btnPlaySuccess_Click(object sender, System.EventArgs e)
		{
			PlayAudioFile(txtAudioFileSuccess.Text);
		}

		private void btnPlayFixed_Click(object sender, System.EventArgs e)
		{
			PlayAudioFile(txtAudioFileFixed.Text);
		}

		private void btnPlayBroken_Click(object sender, System.EventArgs e)
		{
			PlayAudioFile(txtAudioFileBroken.Text);
		}

		private void btnPlayFailing_Click(object sender, System.EventArgs e)
		{
			PlayAudioFile(txtAudioFileFailing.Text);
		}

		void PlayAudioFile(string fileName)
		{
			if (fileName==null || fileName.Trim().Length==0)
				return;

			if (!File.Exists(fileName))
			{
				MessageBox.Show("The specified audio file was not found.", "File not found", MessageBoxButtons.OK, MessageBoxIcon.Error);
				return;
			}

			Audio.PlaySound(fileName, false, true);
		}

		#endregion

		#region Testing connection

		private void ShowError(string message) 
		{
			MessageBox.Show(this, message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
		}

		#endregion

		private void addProjectButton_Click(object sender, System.EventArgs e)
		{
			ProjectForm form = new ProjectForm(new Project());
			form.Show();
			form.Closed += new EventHandler(form_Closed);
		}

		private void form_Closed(object sender, EventArgs e)
		{
			if (sender is ProjectForm)
			{
				ProjectForm pf = (ProjectForm) sender;
				Project project = pf.Project;

				if (project != null) 
				{
					if (!_settings.Projects.Contains(project)) 
					{
						project.OnPolled += new PolledEventHandler(Project_OnPolled);

						_settings.Projects.Add(project);
						monitor.visitProject(project);
					}
					UpdateProjectList();
				}
			}
		}

		private void propertiesMenuItem_Click(object sender, System.EventArgs e)
		{
			IEnumerator enumr = this.projectListView.SelectedIndices.GetEnumerator();
			enumr.MoveNext();
			Project p = ((Project) this._settings.Projects.ToArray()[(int) enumr.Current]);
			ProjectForm pf = new ProjectForm(p);
			pf.Closed += new EventHandler(form_Closed);
			pf.Show();
		}

		private void removeMenuItem_Click(object sender, System.EventArgs e)
		{
			IEnumerator enumr = this.projectListView.SelectedIndices.GetEnumerator();
			enumr.MoveNext();
			
			
			((Project) this._settings.Projects.ToArray()[(int) enumr.Current]).StopPolling();
			this._settings.Projects.RemoveAt((int) enumr.Current);
			//Console.WriteLine(sender.ToString());

			UpdateProjectList();
		}

		private void removeProjectButton_Click(object sender, System.EventArgs e)
		{
			removeMenuItem_Click(sender, e);
		}

		private void SettingsForm_Load(object sender, System.EventArgs e)
		{
			UpdateProjectList();
		}

		private void Project_OnPolled(object sauce, PolledEventArgs e)
		{
			UpdateProjectList();
		}

		private void proxyConfigurationButton_Click(object sender, System.EventArgs e)
		{
			ProxyForm pf = new ProxyForm(this._settings);
			pf.Show();
		}

		public void visitProject(Project project)
		{
			project.OnPolled += new PolledEventHandler(Project_OnPolled);
		}
	}
	public class ProjectMenuItem : MenuItem 
	{
		private Project project;
		public ProjectMenuItem(Project p) 
		{
			this.project = p;
			base.Text = p.Projectname;
			
			MenuItem lauchUrl = new MenuItem("open build page");
			lauchUrl.Click +=new EventHandler(lauchUrl_Click);
			MenuItem forceBuild = new MenuItem("force build");
			forceBuild.Click +=new EventHandler(forceBuild_Click);
			this.MenuItems.Add(lauchUrl);
			this.MenuItems.Add(forceBuild);
		}

		private void lauchUrl_Click(object sender, EventArgs e)
		{
			String url = project.ProjectStatus.BuildStatusUrl;

			if (url==null || url.Trim().Length==0)
				url = project.InstallationUrl + "/public/project/" + project.Projectname;
			if (!(url==null || url.Trim().Length==0))
				Process.Start(url);
		}

		private void forceBuild_Click(object sender, EventArgs e)
		{
			project.ForceBuild();
		}
	}
}
