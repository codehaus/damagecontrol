using System;
using System.Collections;
using System.Diagnostics;
using System.Net;
using System.Threading;
using Nwc.XmlRpc;

namespace ThoughtWorks.DamageControl.DamageControlClientNet
{

	#region Public delegates

	public delegate void BuildOccurredEventHandler(object sauce, BuildOccurredEventArgs e);

	public delegate void PolledEventHandler(object sauce, PolledEventArgs e);

	public delegate void ErrorEventHandler(object sauce, ErrorEventArgs e);

	#endregion

	/// <summary>
	/// Encapsulates all project information for the DamageControl Project.  This class
	/// is designed to work with Xml serialisation, for persisting user settings.
	/// </summary>
	//[XmlRootAttribute("DamageControlMonitor", Namespace="http://damagecontrol.codehaus.org", IsNullable=false)]
	[Serializable]
	public class Project
	{
		#region member variables

		private string installationurl;
		private string username;
		private string password;
		private string projectname;
		private int pollinginterval;
		private static readonly Hashtable _statusMappings = new Hashtable();
		private ProjectStatus _currentProjectStatus = new ProjectStatus("unknown", BuildStatus.Idle, BuildStatus.Idle, "", DateTime.MinValue, "0");
		private Thread thread;

		#endregion

		#region delegates and handlers

		public event PolledEventHandler OnPolled;
		public event BuildOccurredEventHandler OnBuildOccurred;
		public event ErrorEventHandler OnError;

		#endregion

		#region initialization and constructors

		static Project()
		{
			_statusMappings["IDLE"] = BuildStatus.Idle;
			_statusMappings["SUCCESSFUL"] = BuildStatus.Successful;
			_statusMappings["FAILED"] = BuildStatus.Failed;
			_statusMappings["QUEUED"] = BuildStatus.Queued;
			_statusMappings["BUILDING"] = BuildStatus.Building;
			_statusMappings["KILLED"] = BuildStatus.Killed;
			_statusMappings["DETERMINING CHANGESETS"] = BuildStatus.DeterminingChangesets;
			_statusMappings["CHECKING OUT"] = BuildStatus.CheckingOut;
		}

		public Project()
		{
			this.installationurl = "http://localhost:4712/";
			this.pollinginterval = 10000;
			this.projectname = "ray";
			this.thread = new Thread(new ThreadStart(DoPolling));
			thread.Start();
			thread.Suspend();
		}

		public Project(String url, String project)
		{
			this.installationurl = url;
			this.projectname = project;
			this.pollinginterval = 1000;
			this.thread = new Thread(new ThreadStart(DoPolling));
			thread.Start();
			thread.Suspend();
		}

		#endregion

		#region polling control

		public void StartPolling()
		{
			Console.WriteLine("Starting polling on project " + this.projectname);
			if ((pollinginterval > 0) && (!thread.IsAlive))
			{
				this.thread.Resume();
			}
			else
			{
				//this.thread.Start();
				if (thread.IsAlive)
					Console.WriteLine("Thread is still alive");
				if (pollinginterval <= 0)
					Console.WriteLine("Interval is too short");
			}
		}

		public void StopPolling()
		{
			this.thread.Suspend();
		}

		#endregion

		#region Properties

		/// <summary>
		/// Gets the Url of the build results web page for the current project.
		/// </summary>
		public string WebUrl
		{
			get { return _currentProjectStatus.BuildStatusUrl; }
		}

		public string InstallationUrl
		{
			get { return this.installationurl; }
			set { this.installationurl = value; }
		}

		public string Username
		{
			get { return this.username; }
			set
			{
				this.username = value;
				UpdateCredentials();
			}
		}

		private void UpdateCredentials()
		{
			if ((this.username != null) && (this.password != null))
			{
				RequestSettings settings = RequestSettings.getInstance();
				settings.Credentials = new NetworkCredential(this.username, this.password);
			}
		}

		public string Password
		{
			get { return this.password; }
			set
			{
				this.password = value;
				UpdateCredentials();
			}
		}


		public string Projectname
		{
			get { return this.projectname; }
			set { this.projectname = value; }
		}

		public int Interval
		{
			get { return this.pollinginterval; }
			set
			{
				bool wasalive = false;
				if (thread.IsAlive)
				{
					wasalive = true;
					thread.Suspend();
				}
				this.pollinginterval = value;
				if ((pollinginterval > 0) && (wasalive))
				{
					thread.Resume();
				}
			}
		}

		public ProjectStatus ProjectStatus
		{
			get { return _currentProjectStatus; }
		}

		#endregion

		#region Build transition detection

		private bool HasBuildOccurred(ProjectStatus newProjectStatus)
		{
			// If last build date is DateTime.MinValue (struct's default value),
			// then the remote status has not yet been recorded.
			if (_currentProjectStatus.LastBuildDate == DateTime.MinValue)
				return false;

			// compare dates
			return (newProjectStatus.LastBuildDate != _currentProjectStatus.LastBuildDate);
		}

		#endregion

		#region Build transitions

		private BuildTransition GetBuildTransition(ProjectStatus projectStatus)
		{
			bool wasOk = _currentProjectStatus.BuildStatus == BuildStatus.Successful;
			bool isOk = projectStatus.BuildStatus == BuildStatus.Successful;

			if (wasOk && isOk)
				return BuildTransition.StillSuccessful;
			else if (!wasOk && !isOk)
				return BuildTransition.StillFailing;
			else if (wasOk && !isOk)
				return BuildTransition.Broken;
			else if (!wasOk && isOk)
				return BuildTransition.Fixed;

			throw new Exception("The universe has gone crazy.");
		}

		#endregion

		#region polling

		private void Poll()
		{
			Console.WriteLine("Polling on project " + this.projectname);
			try
			{
				ProjectStatus latestProjectStatus = GetRemoteProjectStatus();
				bool hasBuildOccurred = HasBuildOccurred(latestProjectStatus);
				BuildTransition transition = GetBuildTransition(latestProjectStatus);

				_currentProjectStatus = latestProjectStatus;
				OnPolled(this, new PolledEventArgs(latestProjectStatus));

				if (hasBuildOccurred)
				{
					Console.WriteLine("OnBuildOccurred");
					OnBuildOccurred(this, new BuildOccurredEventArgs(latestProjectStatus, transition));
				}
			}
			catch (Exception e)
			{
				OnError(this, new ErrorEventArgs(e));
			}
		}

		private void DoPolling()
		{
			while (true)
			{
				Poll();
				Thread.Sleep(this.pollinginterval);
			}
		}

		#endregion

		#region damagecontrol communication

		private Hashtable CallDamageControlServer(string methodName)
		{
			UpdateCredentials();
			XmlRpcRequest client = new XmlRpcRequest();
			client.MethodName = methodName;
			client.Params.Add(this.projectname);

			string url = this.installationurl + "public/xmlrpc";
			//Console.WriteLine("Calling " + url);
			XmlRpcResponse response = client.Send(url);
			if (response.IsFault)
			{
				throw new Exception(response.FaultString);
			}
			if (response.Value == null)
			{
				throw new Exception(string.Format("Project '{0}' does not exist", this.projectname));
			}

			Hashtable ret = response.Value as Hashtable;
			if (ret == null)
			{
				throw new Exception("XMLRPC connection not compatible");
			}
			return ret;
		}

		public void ForceBuild()
		{
			XmlRpcRequest client = new XmlRpcRequest();
			client.MethodName = "build.request";
			client.Params.Add(this.projectname);

			string url = this.installationurl + "private/xmlrpc";
			XmlRpcResponse response = client.Send(url);
			if (response.IsFault)
			{
				Console.WriteLine(response.FaultString);
			}
		}

		private ProjectStatus GetRemoteProjectStatus()
		{
			Hashtable lastCompletedBuildStatusRaw = CallDamageControlServer("status.last_completed_build");
			DumpHashtable("last", lastCompletedBuildStatusRaw);
			BuildStatus lastCompletedBuildStatus = ToBuildStatus((string) lastCompletedBuildStatusRaw["status"]);
			string lastCompletedBuildLabel = lastCompletedBuildStatusRaw["label"] == null ? "none" : lastCompletedBuildStatusRaw["label"].ToString();
			string lastCompletedBuildUrl = (string) lastCompletedBuildStatusRaw["url"];
			DateTime lastCompletedBuildDate = (DateTime) lastCompletedBuildStatusRaw["dc_start_time"];

			Hashtable currentBuildStatusRaw = CallDamageControlServer("status.current_build");
			DumpHashtable("current", currentBuildStatusRaw);
			BuildStatus currentBuildStatus = ToBuildStatus((string) currentBuildStatusRaw["status"]);

			return new ProjectStatus(this.projectname, currentBuildStatus, lastCompletedBuildStatus, lastCompletedBuildUrl, lastCompletedBuildDate, lastCompletedBuildLabel);
		}

		private void DumpHashtable(string name, Hashtable table)
		{
			Debug.WriteLine("============== " + name);
			foreach (Object key in table.Keys)
			{
				Debug.WriteLine(string.Format("{0} = {1}", key, table[key]));
			}
			Debug.WriteLine("");
		}

		private static BuildStatus ToBuildStatus(string damagecontrolStatus)
		{
			if (damagecontrolStatus == null)
			{
				return BuildStatus.Idle;
			}
			object resultingStatus = _statusMappings[damagecontrolStatus];
			if (resultingStatus == null)
			{
				return BuildStatus.Idle;
			}
			return (BuildStatus) resultingStatus;
		}

		#endregion

		public string TestConnection()
		{
			try
			{
				/*
				DamageControlTest test = new DamageControlTest();
				test.Url = txtServerUrl.Text;

				// trying a simple ping
				string response = test.Ping();
				if (response != "Response from DamageControl")
				{
					throw new Exception("Invalid response from server");
				}

				// trying a simple echo
				response = test.Echo("This is a test from DCTray.NET");
				if (response != "This is a test from DCTray.NET")
				{
					throw new Exception("Invalid response from server");
				}

				DamageControlStatus status = new DamageControlStatus();
				status.Url = txtServerUrl.Text;

				if(null == status.GetCurrentBuild(txtProjectName.Text))
				{
					throw new Exception(string.Format("Project '{0}' does not exist on the server (at this time)", txtProjectName.Text));
				}
				*/

				// trying a simple ping
				XmlRpcRequest client = new XmlRpcRequest();
				client.MethodName = "test.ping";
				string url = this.installationurl + "public/xmlrpc";
				XmlRpcResponse response = client.Send(url);
				if (response.IsFault)
				{
					//ShowError(response.FaultString);
					return "Cannot ping, " + response.FaultString;
				}

				// trying a simple echo
				client = new XmlRpcRequest();
				client.MethodName = "test.echo";
				client.Params.Add("This is a test from DamageControl Monitor");
				response = client.Send(url);
				if (response.IsFault)
				{
					return "Cannot echo: " + response.FaultString;
				}
				if ((string) response.Value != "This is a test from DamageControl Monitor")
				{
					return "Cannot echo: XMLRPC connection is not compatible";
				}

				// checking whether that project exists
				client = new XmlRpcRequest();
				client.MethodName = "status.current_build";
				client.Params.Add(this.projectname);
				response = client.Send(url);
				if (response.IsFault)
				{
					return "Cannot get status: " + response.FaultString;
				}
				if (response.Value == null)
				{
					return string.Format("Cannot get status: Project '{0}' does not exist", this.projectname);
				}
				return null;
			}
			catch (Exception ex)
			{
				Console.WriteLine(ex.StackTrace);
				return "Generic error: " + ex.Message;
			}
		}
	}

	#region Event argument classes

	public class BuildOccurredEventArgs : EventArgs
	{
		private ProjectStatus _projectStatus;
		private BuildTransition _transition;

		public BuildOccurredEventArgs(ProjectStatus newProjectStatus, BuildTransition transition)
		{
			_projectStatus = newProjectStatus;
			_transition = transition;
		}

		public ProjectStatus ProjectStatus
		{
			get { return _projectStatus; }
		}

		public BuildTransition BuildTransition
		{
			get { return _transition; }
		}

		public BuildTransitionAttribute BuildTransitionInfo
		{
			get { return BuildTransitionUtil.GetBuildTransitionAttribute(_transition); }
		}
	}

	public class PolledEventArgs : EventArgs
	{
		private ProjectStatus _projectStatus;

		public PolledEventArgs(ProjectStatus projectStatus)
		{
			_projectStatus = projectStatus;
		}

		public ProjectStatus ProjectStatus
		{
			get { return _projectStatus; }
		}
	}

	public class ErrorEventArgs : EventArgs
	{
		private Exception _exception;

		public ErrorEventArgs(Exception exception)
		{
			_exception = exception;
		}

		public Exception Exception
		{
			get { return _exception; }
		}
	}

	#endregion
}