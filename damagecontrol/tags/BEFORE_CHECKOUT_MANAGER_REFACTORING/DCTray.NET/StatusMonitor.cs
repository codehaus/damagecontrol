using System;
using System.Collections;
using System.ComponentModel;
using System.Diagnostics;
using System.Windows.Forms;
using Nwc.XmlRpc;

namespace ThoughtWorks.DamageControl.DCTray
{
	#region Public delegates

	public delegate void BuildOccurredEventHandler(object sauce, BuildOccurredEventArgs e);
	public delegate void PolledEventHandler(object sauce, PolledEventArgs e);
	public delegate void ErrorEventHandler(object sauce, ErrorEventArgs e);

	#endregion

	/// <summary>
	/// Monitors a remote DamageControl instance, and raises events in
	/// responses to changes in the server's state.
	/// </summary>
	public class StatusMonitor : Component
	{
		#region Field declarations

		public event BuildOccurredEventHandler BuildOccurred;
		public event PolledEventHandler Polled;
		public event ErrorEventHandler Error;

		Timer pollTimer;
		IContainer components;

		ProjectStatus _currentProjectStatus = new ProjectStatus("unknown", BuildStatus.Unknown, BuildStatus.Unknown, "http://damagecontrol.codehaus.org", DateTime.MinValue, "0");
		Settings _settings;

		#endregion

		#region Constructors

		public StatusMonitor(IContainer container)
		{
			container.Add(this);
			InitializeComponent();
		}

		public StatusMonitor()
		{
			InitializeComponent();
		}


		#endregion

		#region Properties

		/// <summary>
		/// Gets the Url of the build results web page for the current project.
		/// </summary>
		public string WebUrl
		{
			get
			{
				return _currentProjectStatus.BuildStatusUrl;
			}
		}

		public Settings Settings
		{
			get
			{
				return _settings;
			}
			set
			{
				_settings = value;
			}
		}

		public ProjectStatus ProjectStatus
		{
			get
			{
				return _currentProjectStatus;
			}
		}

		#endregion

		#region Component Designer generated code
		
		/// <summary> 
		/// Clean up any resources being used.
		/// </summary>
		protected override void Dispose(bool disposing)
		{
			if (disposing)
			{
				if (components!=null)
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
			this.pollTimer = new System.Windows.Forms.Timer(this.components);
			// 
			// pollTimer
			// 
			this.pollTimer.Interval = 15000;
			this.pollTimer.Tick += new System.EventHandler(this.pollTimer_Tick);

		}

		#endregion

		#region Polling

		public void StartPolling()
		{
			// poll immediately
			Poll();

			// use timer to ensure periodic polling
			pollTimer.Enabled = true;
			pollTimer.Start();
		}

		public void StopPolling()
		{
			pollTimer.Enabled = false;
			pollTimer.Stop();
		}

		void pollTimer_Tick(object sender, EventArgs e)
		{
			Poll();

			// update interval, in case it has changed
			pollTimer.Interval = Settings.PollingIntervalSeconds * 1000;
		}

		public void Poll()
		{
			// check for any change in status, and raise events accordingly
			try
			{
				// todo: fix me - we need to have the name of the project we're looking at here, so we can
				// report on the right one - jeremy
				ProjectStatus latestProjectStatus = GetRemoteProjectStatus(Settings.ProjectName);

				OnPolled(new PolledEventArgs(latestProjectStatus));

				if (HasBuildOccurred(latestProjectStatus))
				{
					BuildTransition transition = GetBuildTransition(latestProjectStatus);
					OnBuildOccurred(new BuildOccurredEventArgs(latestProjectStatus, transition));
				}

				_currentProjectStatus = latestProjectStatus;
			}
			catch (Exception ex)
			{
				OnError(new ErrorEventArgs(ex));
			}
		}


		#endregion

		#region Build transition detection

		bool HasBuildOccurred(ProjectStatus newProjectStatus)
		{
			// If last build date is DateTime.MinValue (struct's default value),
			// then the remote status has not yet been recorded.
			if (_currentProjectStatus.LastBuildDate==DateTime.MinValue)
				return false;

			// compare dates
			return (newProjectStatus.LastBuildDate!=_currentProjectStatus.LastBuildDate);
		}


		#endregion

		protected virtual void OnPolled(PolledEventArgs e)
		{
			if (Polled!=null)
				Polled(this, e);
		}

		protected virtual void OnBuildOccurred(BuildOccurredEventArgs e)
		{
			if (BuildOccurred!=null)
				BuildOccurred(this, e);
		}

		protected virtual void OnError(ErrorEventArgs e)
		{
			if (Error!=null)
				Error(this, e);
		}

		static readonly Hashtable _statusMappings = new Hashtable();

		static StatusMonitor()
		{
			_statusMappings["IDLE"] = BuildStatus.Nothing;
			_statusMappings["SUCCESSFUL"] = BuildStatus.Success;
			_statusMappings["FAILED"] = BuildStatus.Failure;
			_statusMappings["QUEUED"] = BuildStatus.Working;
			_statusMappings["BUILDING"] = BuildStatus.Working;
			_statusMappings["CHECKING OUT"] = BuildStatus.Working;
		}

		static BuildStatus ToBuildStatus(string damagecontrolStatus) 
		{
			if(damagecontrolStatus == null)
			{
				return BuildStatus.Unknown;
			}
			object resultingStatus = _statusMappings[damagecontrolStatus];
			if(resultingStatus == null)
			{
				return BuildStatus.Unknown;
			}
			return (BuildStatus) resultingStatus;
		}
		
		ProjectStatus GetRemoteProjectStatus(string projectName)
		{
			Hashtable buildStatusRaw = CallDamageControlServer("status.last_completed_build", projectName);
			DumpHashtable("last", buildStatusRaw);
			BuildStatus buildStatus = ToBuildStatus((string) buildStatusRaw["status"]);
			string label = buildStatusRaw["label"] == null ? "none" : buildStatusRaw["label"].ToString();
			string url = (string) buildStatusRaw["url"];
			DateTime lastBuildDate = TimestampToDate((string) buildStatusRaw["timestamp"]);

			Hashtable currentBuildStatusRaw = CallDamageControlServer("status.current_build", projectName);
			DumpHashtable("current", currentBuildStatusRaw);
			BuildStatus currentBuildStatus = ToBuildStatus((string) currentBuildStatusRaw["status"]);

			return new ProjectStatus(projectName, currentBuildStatus, buildStatus, url, lastBuildDate, label);
		}

		DateTime TimestampToDate(string timestamp) 
		{
			try 
			{
				return DateTime.ParseExact(timestamp, "yyyyMMddHHmmss", null);
			}
			catch (Exception e)
			{
				Debug.WriteLine("could not parse date '" + timestamp + "': " + e);
				return DateTime.Today;
			}
		}

		void DumpHashtable(string name, Hashtable table)
		{
			Debug.WriteLine("============== " + name);
			foreach(Object key in table.Keys) 
			{
				Debug.WriteLine(string.Format("{0} = {1}", key, table[key]));
			}
			Debug.WriteLine("");
		}

		Hashtable CallDamageControlServer(string methodName, string projectName)
		{
			XmlRpcRequest client = new XmlRpcRequest();
			client.MethodName = methodName;
			client.Params.Add(projectName);
			XmlRpcResponse response = client.Send(Settings.RemoteServerUrl);
			if (response.IsFault) 
			{
				throw new Exception(response.FaultString);
			}
			if (response.Value == null)
			{
				throw new Exception(string.Format("Project '{0}' does not exist", projectName));
			}
			Hashtable ret = response.Value as Hashtable;
			if (ret == null)
			{
				throw new Exception("XMLRPC connection not compatible");
			}
			return ret;
		}

		public void ForceBuild(string projectName)
		{
			throw new Exception("Not implemented yet!");
		}

		#region Build transitions

		BuildTransition GetBuildTransition(ProjectStatus projectStatus)
		{
			bool wasOk = _currentProjectStatus.BuildStatus==BuildStatus.Success;
			bool isOk = projectStatus.BuildStatus==BuildStatus.Success;

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
	}

	#region Event argument classes

	public class BuildOccurredEventArgs : EventArgs
	{
		ProjectStatus _projectStatus;
		BuildTransition _transition;

		public BuildOccurredEventArgs(ProjectStatus newProjectStatus, BuildTransition transition)
		{
			_projectStatus = newProjectStatus;
			_transition = transition;
		}

		public ProjectStatus ProjectStatus
		{
			get
			{
				return _projectStatus;
			}
		}

		public BuildTransition BuildTransition
		{
			get
			{
				return _transition;
			}
		}

		public BuildTransitionAttribute BuildTransitionInfo
		{
			get
			{
				return BuildTransitionUtil.GetBuildTransitionAttribute(_transition);
			}
		}
	}

	public class PolledEventArgs : EventArgs
	{
		ProjectStatus _projectStatus;

		public PolledEventArgs(ProjectStatus projectStatus)
		{
			_projectStatus = projectStatus;
		}

		public ProjectStatus ProjectStatus
		{
			get
			{
				return _projectStatus;
			}
		}
	}

	public class ErrorEventArgs : EventArgs
	{
		Exception _exception;

		public ErrorEventArgs(Exception exception)
		{
			_exception = exception;
		}

		public Exception Exception
		{
			get
			{
				return _exception;
			}
		}
	}


	#endregion
}
