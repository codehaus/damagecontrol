using System;
using System.Drawing;
using System.Collections;
using System.ComponentModel;
using System.Windows.Forms;
using ThoughtWorks.DamageControl.DamageControlClientNet;

namespace ThoughtWorks.DamageControl.WindowsTray
{
	/// <summary>
	/// Summary description for ProjectForm.
	/// </summary>
	public class ProjectForm : System.Windows.Forms.Form
	{
		private System.Windows.Forms.Label label1;
		private System.Windows.Forms.Label label2;
		private System.Windows.Forms.GroupBox groupBox1;
		private System.Windows.Forms.GroupBox groupBox2;
		private System.Windows.Forms.Label label3;
		private System.Windows.Forms.Label label4;
		/// <summary>
		/// Required designer variable.
		/// </summary>
		private System.ComponentModel.Container components = null;
		private System.Windows.Forms.TextBox urlTextBox;
		private System.Windows.Forms.TextBox projectNameTextBox;
		private System.Windows.Forms.CheckBox httpAuthCheckBox;
		private System.Windows.Forms.TextBox usernameTextBox;
		private System.Windows.Forms.TextBox passwordTextBox;
		private System.Windows.Forms.Button okButton;
		private System.Windows.Forms.Button cancelButton;
		private System.Windows.Forms.Button testConnectionButton;
		private System.Windows.Forms.Label label5;
		private System.Windows.Forms.NumericUpDown intervalUpDown;
		private System.Windows.Forms.Label label6;

		private Project project;

		public Project Project 
		{
			get 
			{
				return this.project;
			}
		}

		public ProjectForm(Project p)
		{
			this.project = p;
			this.project.StopPolling();
			InitializeComponent();
			this.urlTextBox.Text = this.project.InstallationUrl;
			this.projectNameTextBox.Text = this.project.Projectname;
			this.intervalUpDown.Value = this.project.Interval;
			if ((this.project.Username==null)&&(this.project.Password==null))
			{
				this.httpAuthCheckBox.Checked = false;
				this.usernameTextBox.ReadOnly = true;
				this.passwordTextBox.ReadOnly = true;
			}
			else
			{
				this.usernameTextBox.Text = this.project.Username;
				this.passwordTextBox.Text = this.project.Password;
				this.httpAuthCheckBox.Checked = true;
				this.usernameTextBox.ReadOnly = false;
				this.passwordTextBox.ReadOnly = false;
			}
		}

		public ProjectForm()
		{
			this.project = new Project();
			InitializeComponent();
		}

		/// <summary>
		/// Clean up any resources being used.
		/// </summary>
		protected override void Dispose( bool disposing )
		{
			if( disposing )
			{
				if(components != null)
				{
					components.Dispose();
				}
			}
			base.Dispose( disposing );
		}

		#region Windows Form Designer generated code
		/// <summary>
		/// Required method for Designer support - do not modify
		/// the contents of this method with the code editor.
		/// </summary>
		private void InitializeComponent()
		{
			this.label1 = new System.Windows.Forms.Label();
			this.urlTextBox = new System.Windows.Forms.TextBox();
			this.label2 = new System.Windows.Forms.Label();
			this.projectNameTextBox = new System.Windows.Forms.TextBox();
			this.httpAuthCheckBox = new System.Windows.Forms.CheckBox();
			this.groupBox1 = new System.Windows.Forms.GroupBox();
			this.groupBox2 = new System.Windows.Forms.GroupBox();
			this.passwordTextBox = new System.Windows.Forms.TextBox();
			this.label4 = new System.Windows.Forms.Label();
			this.usernameTextBox = new System.Windows.Forms.TextBox();
			this.label3 = new System.Windows.Forms.Label();
			this.okButton = new System.Windows.Forms.Button();
			this.cancelButton = new System.Windows.Forms.Button();
			this.testConnectionButton = new System.Windows.Forms.Button();
			this.label5 = new System.Windows.Forms.Label();
			this.intervalUpDown = new System.Windows.Forms.NumericUpDown();
			this.label6 = new System.Windows.Forms.Label();
			this.groupBox1.SuspendLayout();
			this.groupBox2.SuspendLayout();
			((System.ComponentModel.ISupportInitialize)(this.intervalUpDown)).BeginInit();
			this.SuspendLayout();
			// 
			// label1
			// 
			this.label1.Location = new System.Drawing.Point(8, 24);
			this.label1.Name = "label1";
			this.label1.Size = new System.Drawing.Size(120, 23);
			this.label1.TabIndex = 0;
			this.label1.Text = "Damagecontrol URL";
			// 
			// urlTextBox
			// 
			this.urlTextBox.Location = new System.Drawing.Point(128, 16);
			this.urlTextBox.Name = "urlTextBox";
			this.urlTextBox.Size = new System.Drawing.Size(224, 20);
			this.urlTextBox.TabIndex = 1;
			this.urlTextBox.Text = "http://192.168.0.2/";
			// 
			// label2
			// 
			this.label2.Location = new System.Drawing.Point(8, 48);
			this.label2.Name = "label2";
			this.label2.Size = new System.Drawing.Size(120, 23);
			this.label2.TabIndex = 2;
			this.label2.Text = "Project name";
			// 
			// projectNameTextBox
			// 
			this.projectNameTextBox.Location = new System.Drawing.Point(128, 48);
			this.projectNameTextBox.Name = "projectNameTextBox";
			this.projectNameTextBox.Size = new System.Drawing.Size(224, 20);
			this.projectNameTextBox.TabIndex = 3;
			this.projectNameTextBox.Text = "jira";
			// 
			// httpAuthCheckBox
			// 
			this.httpAuthCheckBox.Location = new System.Drawing.Point(8, 16);
			this.httpAuthCheckBox.Name = "httpAuthCheckBox";
			this.httpAuthCheckBox.Size = new System.Drawing.Size(136, 24);
			this.httpAuthCheckBox.TabIndex = 4;
			this.httpAuthCheckBox.Text = "HTTP Authentication";
			this.httpAuthCheckBox.CheckedChanged += new System.EventHandler(this.httpAuthCheckBox_CheckedChanged);
			// 
			// groupBox1
			// 
			this.groupBox1.Controls.Add(this.label1);
			this.groupBox1.Controls.Add(this.label2);
			this.groupBox1.Controls.Add(this.urlTextBox);
			this.groupBox1.Controls.Add(this.projectNameTextBox);
			this.groupBox1.Location = new System.Drawing.Point(16, 16);
			this.groupBox1.Name = "groupBox1";
			this.groupBox1.Size = new System.Drawing.Size(368, 80);
			this.groupBox1.TabIndex = 5;
			this.groupBox1.TabStop = false;
			this.groupBox1.Text = "Project Settings";
			// 
			// groupBox2
			// 
			this.groupBox2.Controls.Add(this.label6);
			this.groupBox2.Controls.Add(this.intervalUpDown);
			this.groupBox2.Controls.Add(this.label5);
			this.groupBox2.Controls.Add(this.passwordTextBox);
			this.groupBox2.Controls.Add(this.label4);
			this.groupBox2.Controls.Add(this.usernameTextBox);
			this.groupBox2.Controls.Add(this.label3);
			this.groupBox2.Controls.Add(this.httpAuthCheckBox);
			this.groupBox2.Location = new System.Drawing.Point(16, 112);
			this.groupBox2.Name = "groupBox2";
			this.groupBox2.Size = new System.Drawing.Size(368, 120);
			this.groupBox2.TabIndex = 6;
			this.groupBox2.TabStop = false;
			this.groupBox2.Text = "Connection Settings";
			// 
			// passwordTextBox
			// 
			this.passwordTextBox.Location = new System.Drawing.Point(128, 64);
			this.passwordTextBox.Name = "passwordTextBox";
			this.passwordTextBox.PasswordChar = '*';
			this.passwordTextBox.ReadOnly = true;
			this.passwordTextBox.Size = new System.Drawing.Size(224, 20);
			this.passwordTextBox.TabIndex = 8;
			this.passwordTextBox.Text = "";
			// 
			// label4
			// 
			this.label4.Location = new System.Drawing.Point(8, 64);
			this.label4.Name = "label4";
			this.label4.Size = new System.Drawing.Size(112, 23);
			this.label4.TabIndex = 7;
			this.label4.Text = "Password";
			// 
			// usernameTextBox
			// 
			this.usernameTextBox.Location = new System.Drawing.Point(128, 40);
			this.usernameTextBox.Name = "usernameTextBox";
			this.usernameTextBox.ReadOnly = true;
			this.usernameTextBox.Size = new System.Drawing.Size(224, 20);
			this.usernameTextBox.TabIndex = 6;
			this.usernameTextBox.Text = "";
			// 
			// label3
			// 
			this.label3.Location = new System.Drawing.Point(8, 40);
			this.label3.Name = "label3";
			this.label3.Size = new System.Drawing.Size(112, 23);
			this.label3.TabIndex = 5;
			this.label3.Text = "Username";
			// 
			// okButton
			// 
			this.okButton.Location = new System.Drawing.Point(224, 240);
			this.okButton.Name = "okButton";
			this.okButton.TabIndex = 7;
			this.okButton.Text = "OK";
			this.okButton.Click += new System.EventHandler(this.okButton_Click);
			// 
			// cancelButton
			// 
			this.cancelButton.DialogResult = System.Windows.Forms.DialogResult.Cancel;
			this.cancelButton.Location = new System.Drawing.Point(312, 240);
			this.cancelButton.Name = "cancelButton";
			this.cancelButton.TabIndex = 8;
			this.cancelButton.Text = "Cancel";
			this.cancelButton.Click += new System.EventHandler(this.cancelButton_Click);
			// 
			// testConnectionButton
			// 
			this.testConnectionButton.Location = new System.Drawing.Point(16, 240);
			this.testConnectionButton.Name = "testConnectionButton";
			this.testConnectionButton.Size = new System.Drawing.Size(112, 23);
			this.testConnectionButton.TabIndex = 9;
			this.testConnectionButton.Text = "Test connection";
			this.testConnectionButton.Click += new System.EventHandler(this.testConnectionButton_Click);
			// 
			// label5
			// 
			this.label5.Location = new System.Drawing.Point(8, 88);
			this.label5.Name = "label5";
			this.label5.TabIndex = 9;
			this.label5.Text = "Polling Interval";
			// 
			// intervalUpDown
			// 
			this.intervalUpDown.Increment = new System.Decimal(new int[] {
																			 1000,
																			 0,
																			 0,
																			 0});
			this.intervalUpDown.Location = new System.Drawing.Point(128, 88);
			this.intervalUpDown.Maximum = new System.Decimal(new int[] {
																		   100000,
																		   0,
																		   0,
																		   0});
			this.intervalUpDown.Minimum = new System.Decimal(new int[] {
																		   1000,
																		   0,
																		   0,
																		   0});
			this.intervalUpDown.Name = "intervalUpDown";
			this.intervalUpDown.TabIndex = 10;
			this.intervalUpDown.TextAlign = System.Windows.Forms.HorizontalAlignment.Right;
			this.intervalUpDown.ThousandsSeparator = true;
			this.intervalUpDown.Value = new System.Decimal(new int[] {
																		 1000,
																		 0,
																		 0,
																		 0});
			// 
			// label6
			// 
			this.label6.Location = new System.Drawing.Point(248, 88);
			this.label6.Name = "label6";
			this.label6.TabIndex = 11;
			this.label6.Text = "milliseconds";
			// 
			// ProjectForm
			// 
			this.AcceptButton = this.okButton;
			this.AutoScaleBaseSize = new System.Drawing.Size(5, 13);
			this.CancelButton = this.cancelButton;
			this.ClientSize = new System.Drawing.Size(392, 269);
			this.Controls.Add(this.testConnectionButton);
			this.Controls.Add(this.cancelButton);
			this.Controls.Add(this.okButton);
			this.Controls.Add(this.groupBox2);
			this.Controls.Add(this.groupBox1);
			this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedToolWindow;
			this.Name = "ProjectForm";
			this.Text = "ProjectForm";
			this.groupBox1.ResumeLayout(false);
			this.groupBox2.ResumeLayout(false);
			((System.ComponentModel.ISupportInitialize)(this.intervalUpDown)).EndInit();
			this.ResumeLayout(false);

		}
		#endregion

		private void httpAuthCheckBox_CheckedChanged(object sender, System.EventArgs e)
		{
			if (httpAuthCheckBox.Checked) 
			{
				this.usernameTextBox.ReadOnly = false;
				this.passwordTextBox.ReadOnly = false;
			}
			else 
			{
				this.usernameTextBox.ReadOnly = true;
				this.passwordTextBox.ReadOnly = true;
			}
		}

		private void cancelButton_Click(object sender, System.EventArgs e)
		{
			this.project = null;
			this.Hide();
			this.Close();
		}

		private void UpdateProjectFromForm()
		{
			this.project.InstallationUrl = this.urlTextBox.Text;
			this.project.Projectname = this.projectNameTextBox.Text;
			this.project.Interval = (int) this.intervalUpDown.Value;
			Console.WriteLine("ok button clicked");
			this.project.OnPolled += new PolledEventHandler(project_OnPolled);
			this.project.OnError += new ErrorEventHandler(project_OnError);
			if (this.httpAuthCheckBox.Checked) 
			{
				this.project.Password = this.passwordTextBox.Text;
				this.project.Username = this.usernameTextBox.Text;
			}
			else 
			{
				this.project.Password = null;
				this.project.Username = null;
			}
		}

		private void okButton_Click(object sender, System.EventArgs e)
		{
			UpdateProjectFromForm();
			project.StartPolling();
			this.Close();
		}

		private void project_OnPolled(object sauce, PolledEventArgs e)
		{
			Console.WriteLine(e.ProjectStatus.BuildStatusUrl);
		}

		private void project_OnError(object sauce, ErrorEventArgs e)
		{
			Console.WriteLine(e.Exception.Message);
		}

		private void testConnectionButton_Click(object sender, System.EventArgs e)
		{
			UpdateProjectFromForm();
			string errormessage = this.project.TestConnection();
			if (errormessage==null) 
			{
				MessageBox.Show(this, "All connection settings are OK.");
			}
			else
			{
				MessageBox.Show(this, "Could not establish connection: " + errormessage);
			}
		}
	}
}
