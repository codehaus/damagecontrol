using System;
using System.Threading;
using System.Collections;
using System.Diagnostics;
using System.Net;
using Nwc.XmlRpc;
using System.Xml.Serialization;

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
		static readonly Hashtable _statusMappings = new Hashtable();
		private ProjectStatus _currentProjectStatus = new ProjectStatus("unknown", BuildStatus.Unknown, BuildStatus.Unknown, "", DateTime.MinValue, "0");
		private Thread thread;
		private CredentialCache credcache;
		#endregion

		#region delegates and handlers

		public event PolledEventHandler OnPolled;
		public event BuildOccurredEventHandler OnBuildOccurred;
		public event ErrorEventHandler OnError;
		

		#endregion

		#region initialization and constructors
		static Project()
		{
			_statusMappings["IDLE"] = BuildStatus.Nothing;
			_statusMappings["SUCCESSFUL"] = BuildStatus.Success;
			_statusMappings["FAILED"] = BuildStatus.Failure;
			_statusMappings["QUEUED"] = BuildStatus.Working;
			_statusMappings["BUILDING"] = BuildStatus.Working;
			_statusMappings["CHECKING OUT"] = BuildStatus.Working;
		}

		public Project()
		{
			this.installationurl = "http://192.168.0.2/";
			this.pollinginterval = 10000;
			this.thread = new Thread(new ThreadStart(DoPolling));
			thread.Start();
			thread.Suspend();
			this.credcache = new CredentialCache();
		}

		public Project(String url, String project)
		{
			this.installationurl = url;
			this.projectname = project;
			this.pollinginterval = 1000;
			this.thread = new Thread(new ThreadStart(DoPolling));
			thread.Start();
			thread.Suspend();
			this.credcache = new CredentialCache();
		}
		#endregion

		#region polling control
		public void StartPolling() 
		{

			if ((pollinginterval > 0)&&(!thread.IsAlive)) 
			{
				this.thread.Resume();
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
			get
			{
				return _currentProjectStatus.BuildStatusUrl;
			}
		}

		public string InstallationUrl
		{
			get
			{
				return this.installationurl;
			}
			set 
			{
				this.installationurl = value;
			}
		}

		public string Username
		{
			get
			{
				return this.username;
			}
			set
			{
				this.username = value;
				UpdateCredentials();
			}
		}

		private void UpdateCredentials()
		{
			if ((this.username!=null)&&(this.password!=null)) 
			{
				RequestSettings settings = RequestSettings.getInstance();
				settings.Credentials = new NetworkCredential(this.username, this.password);
			}
		}

		public string Password
		{
			get
			{
				return this.password;
			}
			set
			{
				this.password = value;
				UpdateCredentials();
			}
		}


		public string Projectname
		{
			get 
			{
				return this.projectname;
			}
			set 
			{
				this.projectname = value;
			}
		}

		public int Interval 
		{
			get 
			{
				return this.pollinginterval;
			}
			set 
			{
				thread.Suspend();
				this.pollinginterval = value;
				if (pollinginterval>0)
				{
					thread.Resume();
				}
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

		#region polling
		private void Poll()
		{
			try
			{
				ProjectStatus latestProjectStatus = GetRemoteProjectStatus();
				if (this.OnPolled!=null) 
				{
					OnPolled(this, new PolledEventArgs(latestProjectStatus));
				} 
				else 
				{
				}
				if (HasBuildOccurred(latestProjectStatus))
				{
					if (this.OnBuildOccurred!=null) 
					{
						Console.WriteLine("OnBuildOccurred");
						OnBuildOccurred(this, new BuildOccurredEventArgs(latestProjectStatus, GetBuildTransition(latestProjectStatus)));
					}
				}
				this._currentProjectStatus = latestProjectStatus;
			} 
			catch (Exception e) 
			{
				if (this.OnError!=null) 
				{
					OnError(this, new ErrorEventArgs(e));
				}
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
		Hashtable CallDamageControlServer(string methodName)
		{
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
			Hashtable buildStatusRaw = CallDamageControlServer("status.last_completed_build");
			DumpHashtable("last", buildStatusRaw);
			BuildStatus buildStatus = ToBuildStatus((string) buildStatusRaw["status"]);
			string label = buildStatusRaw["label"] == null ? "none" : buildStatusRaw["label"].ToString();
			string url = (string) buildStatusRaw["url"];
			DateTime lastBuildDate = TimestampToDate((string) buildStatusRaw["timestamp"]);

			Hashtable currentBuildStatusRaw = CallDamageControlServer("status.current_build");
			DumpHashtable("current", currentBuildStatusRaw);
			BuildStatus currentBuildStatus = ToBuildStatus((string) currentBuildStatusRaw["status"]);

			return new ProjectStatus(this.projectname, currentBuildStatus, buildStatus, url, lastBuildDate, label);
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
					return response.FaultString;
				}
				
				// trying a simple echo
				client = new XmlRpcRequest();
				client.MethodName = "test.echo";
				client.Params.Add("This is a test from DamageControl Monitor");
				response = client.Send(url);
				if (response.IsFault) 
				{
					return response.FaultString;
				}
				if ((string) response.Value != "This is a test from DamageControl Monitor") 
				{
					return "XMLRPC connection is not compatible";
				}
				
				// checking whether that project exists
				client = new XmlRpcRequest();
				client.MethodName = "status.current_build";
				client.Params.Add(this.projectname);
				response = client.Send(url);
				if (response.IsFault) 
				{
					return response.FaultString;
				}
				if (response.Value == null)
				{
					return string.Format("Project '{0}' does not exist", this.projectname);
				}
				return null;
			}
			catch (Exception ex)
			{
				System.Diagnostics.Debug.WriteLine(ex.StackTrace);
				return ex.Message;
			}
		}
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
