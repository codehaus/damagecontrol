using System;
using System.Drawing;
using System.Collections;
using System.ComponentModel;
using System.Windows.Forms;
using System.Net;

namespace ThoughtWorks.DamageControl.WindowsTray
{
	/// <summary>
	/// Summary description for ProxyForm.
	/// </summary>
	public class ProxyForm : System.Windows.Forms.Form
	{
		private System.Windows.Forms.TextBox proxyHostTextBox;
		private System.Windows.Forms.TextBox proxyPortTextBox;
		private System.Windows.Forms.Label proxyHostLabel;
		private System.Windows.Forms.Label proxyPortLabel;
		private System.Windows.Forms.CheckBox useProxyCheckBox;
		private System.Windows.Forms.Button cancelButton;
		private System.Windows.Forms.Button okButton;
		private System.Windows.Forms.Button detectButton;
		/// <summary>
		/// Required designer variable.
		/// </summary>
		private System.ComponentModel.Container components = null;
		private System.Windows.Forms.ErrorProvider errorProvider;
		
		private Settings settings;

		public ProxyForm(Settings s)
		{
			this.settings = s;
			InitializeComponent();

			if (settings.ProxyHost==null||settings.ProxyHost.Trim().Equals("")||settings.ProxyPort<=0) 
			{
				this.proxyHostTextBox.Text = "";
				this.proxyPortTextBox.ReadOnly = true;
				this.proxyPortTextBox.Enabled = false;
				this.proxyPortTextBox.Text = "";
				this.useProxyCheckBox.Checked = false;
				this.proxyHostTextBox.ReadOnly = true;
				this.proxyHostTextBox.Enabled = false;
			}
			else
			{
				this.useProxyCheckBox.Checked = true;
				this.proxyPortTextBox.Text = "" + settings.ProxyPort;
				this.proxyHostTextBox.Text = settings.ProxyHost;

				this.proxyPortTextBox.ReadOnly = false;
				this.proxyPortTextBox.Enabled = true;
				this.proxyHostTextBox.ReadOnly = false;
				this.proxyHostTextBox.Enabled = true;
			}
		}

		private ProxyForm()
		{
			//
			// Required for Windows Form Designer support
			//
			InitializeComponent();

			//
			// TODO: Add any constructor code after InitializeComponent call
			//
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
			this.proxyHostTextBox = new System.Windows.Forms.TextBox();
			this.proxyPortTextBox = new System.Windows.Forms.TextBox();
			this.proxyHostLabel = new System.Windows.Forms.Label();
			this.proxyPortLabel = new System.Windows.Forms.Label();
			this.useProxyCheckBox = new System.Windows.Forms.CheckBox();
			this.cancelButton = new System.Windows.Forms.Button();
			this.okButton = new System.Windows.Forms.Button();
			this.detectButton = new System.Windows.Forms.Button();
			this.errorProvider = new System.Windows.Forms.ErrorProvider();
			this.SuspendLayout();
			// 
			// proxyHostTextBox
			// 
			this.proxyHostTextBox.Location = new System.Drawing.Point(88, 48);
			this.proxyHostTextBox.Name = "proxyHostTextBox";
			this.proxyHostTextBox.Size = new System.Drawing.Size(136, 20);
			this.proxyHostTextBox.TabIndex = 0;
			this.proxyHostTextBox.Text = "";
			this.proxyHostTextBox.Validating += new System.ComponentModel.CancelEventHandler(this.proxyHostTextBox_Validating);
			// 
			// proxyPortTextBox
			// 
			this.proxyPortTextBox.Location = new System.Drawing.Point(88, 72);
			this.proxyPortTextBox.Name = "proxyPortTextBox";
			this.proxyPortTextBox.Size = new System.Drawing.Size(136, 20);
			this.proxyPortTextBox.TabIndex = 1;
			this.proxyPortTextBox.Text = "";
			this.proxyPortTextBox.Validating += new System.ComponentModel.CancelEventHandler(this.proxyPortTextBox_Validating);
			// 
			// proxyHostLabel
			// 
			this.proxyHostLabel.Location = new System.Drawing.Point(8, 48);
			this.proxyHostLabel.Name = "proxyHostLabel";
			this.proxyHostLabel.Size = new System.Drawing.Size(80, 23);
			this.proxyHostLabel.TabIndex = 2;
			this.proxyHostLabel.Text = "Proxy host";
			// 
			// proxyPortLabel
			// 
			this.proxyPortLabel.Location = new System.Drawing.Point(8, 72);
			this.proxyPortLabel.Name = "proxyPortLabel";
			this.proxyPortLabel.Size = new System.Drawing.Size(80, 23);
			this.proxyPortLabel.TabIndex = 3;
			this.proxyPortLabel.Text = "Proxy port";
			// 
			// useProxyCheckBox
			// 
			this.useProxyCheckBox.Location = new System.Drawing.Point(8, 16);
			this.useProxyCheckBox.Name = "useProxyCheckBox";
			this.useProxyCheckBox.TabIndex = 4;
			this.useProxyCheckBox.Text = "Use Proxy";
			this.useProxyCheckBox.Validating += new System.ComponentModel.CancelEventHandler(this.useProxyCheckBox_Validating);
			this.useProxyCheckBox.CheckedChanged += new System.EventHandler(this.useProxyCheckBox_CheckedChanged);
			// 
			// cancelButton
			// 
			this.cancelButton.DialogResult = System.Windows.Forms.DialogResult.Cancel;
			this.cancelButton.Location = new System.Drawing.Point(168, 104);
			this.cancelButton.Name = "cancelButton";
			this.cancelButton.TabIndex = 5;
			this.cancelButton.Text = "cancel";
			this.cancelButton.Click += new System.EventHandler(this.cancelButton_Click);
			// 
			// okButton
			// 
			this.okButton.Location = new System.Drawing.Point(88, 104);
			this.okButton.Name = "okButton";
			this.okButton.TabIndex = 6;
			this.okButton.Text = "OK";
			this.okButton.Click += new System.EventHandler(this.okButton_Click);
			// 
			// detectButton
			// 
			this.detectButton.Location = new System.Drawing.Point(8, 104);
			this.detectButton.Name = "detectButton";
			this.detectButton.TabIndex = 7;
			this.detectButton.Text = "Detect";
			this.detectButton.Click += new System.EventHandler(this.detectButton_Click);
			// 
			// errorProvider
			// 
			this.errorProvider.ContainerControl = this;
			// 
			// ProxyForm
			// 
			this.AcceptButton = this.okButton;
			this.AutoScaleBaseSize = new System.Drawing.Size(5, 13);
			this.CancelButton = this.cancelButton;
			this.ClientSize = new System.Drawing.Size(248, 133);
			this.Controls.Add(this.detectButton);
			this.Controls.Add(this.okButton);
			this.Controls.Add(this.cancelButton);
			this.Controls.Add(this.useProxyCheckBox);
			this.Controls.Add(this.proxyPortLabel);
			this.Controls.Add(this.proxyHostLabel);
			this.Controls.Add(this.proxyPortTextBox);
			this.Controls.Add(this.proxyHostTextBox);
			this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedToolWindow;
			this.MaximizeBox = false;
			this.MinimizeBox = false;
			this.Name = "ProxyForm";
			this.ShowInTaskbar = false;
			this.Text = "Proxy Settings";
			this.ResumeLayout(false);

		}
		#endregion

		private void detectButton_Click(object sender, System.EventArgs e)
		{
			WebProxy prxy = WebProxy.GetDefaultProxy();

			if (prxy==null||prxy.Address==null||prxy.Address.Host.Trim().Equals("")||prxy.Address.Port<=0) 
			{
				this.proxyHostTextBox.Text = "";
				this.proxyPortTextBox.ReadOnly = true;
				this.proxyPortTextBox.Enabled = false;
				this.proxyPortTextBox.Text = "";
				this.useProxyCheckBox.Checked = false;
				this.proxyHostTextBox.ReadOnly = true;
				this.proxyHostTextBox.Enabled = false;
			}
			else
			{
				this.useProxyCheckBox.Checked = true;
				this.proxyPortTextBox.Text = "" + prxy.Address.Port;
				this.proxyHostTextBox.Text = prxy.Address.Host;

				this.proxyPortTextBox.ReadOnly = false;
				this.proxyPortTextBox.Enabled = true;
				this.proxyHostTextBox.ReadOnly = false;
				this.proxyHostTextBox.Enabled = true;
			}
		}

		private void cancelButton_Click(object sender, System.EventArgs e)
		{
			this.Hide();
			this.Close();
		}

		private void okButton_Click(object sender, System.EventArgs e)
		{
			if (this.useProxyCheckBox.Checked) 
			{
				try 
				{
					this.settings.ProxyPort = int.Parse(this.proxyPortTextBox.Text);
				} 
				catch (Exception ex)
				{
					errorProvider.SetError(this.proxyPortTextBox, "Please enter a port number greater than zero");
					return;
				}
				this.settings.ProxyHost = this.proxyHostTextBox.Text;
			} 
			else 
			{
				this.settings.ProxyHost = null;
				this.settings.ProxyPort = 0;	
			}
			Hide();
			Close();
		}

		private void proxyPortTextBox_Validating(object sender, System.ComponentModel.CancelEventArgs e)
		{
			if (!this.useProxyCheckBox.Checked)
				return;
			try 
			{
				int.Parse(this.proxyPortTextBox.Text);
			}
			catch (Exception ex)
			{
				errorProvider.SetError(this.proxyPortTextBox, "Please enter a port number greater than zero");
			}
		}

		private void useProxyCheckBox_Validating(object sender, System.ComponentModel.CancelEventArgs e)
		{
			if (!this.useProxyCheckBox.Checked)
				return;
			proxyPortTextBox_Validating(sender, e);
			proxyHostTextBox_Validating(sender, e);
		}

		private void proxyHostTextBox_Validating(object sender, System.ComponentModel.CancelEventArgs e)
		{
			if (!this.useProxyCheckBox.Checked)
				return;
			if (this.proxyHostTextBox.Text.Trim().Equals("")) 
			{
				errorProvider.SetError(this.proxyHostTextBox, "Please enter a proxy host");
			}
		}

		private void useProxyCheckBox_CheckedChanged(object sender, System.EventArgs e)
		{
			if (!this.useProxyCheckBox.Checked) 
			{
				this.proxyPortTextBox.Enabled = false;
				this.proxyPortTextBox.ReadOnly = true;
				this.proxyHostTextBox.Enabled = false;
				this.proxyHostTextBox.ReadOnly = true;
			}
			else
			{
				this.proxyPortTextBox.Enabled = true;
				this.proxyPortTextBox.ReadOnly = false;
				this.proxyHostTextBox.Enabled = true;
				this.proxyHostTextBox.ReadOnly = false;
			}
		}
	}
}
