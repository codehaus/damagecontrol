using System;
using System.Net;
using System.Collections;
using System.Xml.Serialization;
using DamageControlClientNet;
using ThoughtWorks.DamageControl.DamageControlClientNet;
using Nwc.XmlRpc;

namespace ThoughtWorks.DamageControl.WindowsTray
{
	/// <summary>
	/// Encapsulates all user-settings for the DamageControl Monitor.  This class
	/// is designed to work with Xml serialisation, for persisting user settings.
	/// </summary>
	[XmlRootAttribute("DamageControlMonitor", Namespace="http://damagecontrol.codehaus.org", IsNullable=false)]
	public class Settings
	{


		private string proxyhost;
		private int proxyport;

		public string ProxyHost
		{
			set 
			{
				this.proxyhost = value;
				if ((this.proxyhost!=null)&&(this.proxyport>0)) 
				{
					UpdateProxy();
				}
			}
			get 
			{
				return this.proxyhost;
			}
		}
		public int ProxyPort
		{
			set 
			{
				this.proxyport = value;
				if ((this.proxyhost!=null)&&(this.proxyport>0)) 
				{
					UpdateProxy();
				}
			}
			get 
			{
				return this.proxyport;
			}
		}

		private void UpdateProxy() 
		{
			RequestSettings settings = RequestSettings.getInstance();
			settings.Proxy = new WebProxy(this.proxyhost, this.proxyport);
			//settings
		}

		public NotificationBalloon NotificationBalloon;
		
		[System.Xml.Serialization.XmlArray("Projects")]
			// Explicitly tell the serializer to expect the Item class
			// so it can be properly written to XML from the collection:
		[System.Xml.Serialization.XmlArrayItem("project",typeof(Project))]
		public ArrayList Projects;
		public Sounds Sounds = new Sounds();

		public Messages Messages = new Messages();

		public bool ShowExceptions = true;

		public Settings()
		{
		}

		public static Settings CreateDefaultSettings()
		{
			Settings defaults = new Settings();


			defaults.ShowExceptions = true;
			defaults.Projects = new ArrayList();
			

			defaults.Sounds = Sounds.CreateDefaultSettings();
			defaults.NotificationBalloon = NotificationBalloon.CreateDefaultSettings();
			defaults.Messages = Messages.CreateDefaultSettings();
			defaults.ProxyHost = null;
			defaults.ProxyPort = 0;

			return defaults;
		}

		public void accept(ProjectVisitor visitor)
		{
			foreach (Project project in Projects)
			{
				visitor.visitProject(project);
			}
		}
	}

	#region NotificationBalloon

	public class NotificationBalloon
	{
		[XmlAttribute]
		public bool ShowBalloon;

		public static NotificationBalloon CreateDefaultSettings()
		{
			NotificationBalloon defaults = new NotificationBalloon();
			defaults.ShowBalloon = true;
			return defaults;
		}
	}


	#endregion

	#region Messages

	public class Messages
	{
		[XmlArrayItem("Message", typeof(string))]
		public string[] AnotherSuccess = new string[0];

		[XmlArrayItem("Message", typeof(string))]
		public string[] AnotherFailure = new string[0];

		[XmlArrayItem("Message", typeof(string))]
		public string[] Fixed = new string[0];

		[XmlArrayItem("Message", typeof(string))]
		public string[] Broken = new string[0];

		public static Messages CreateDefaultSettings()
		{
			Messages defaults = new Messages();
			defaults.AnotherSuccess = new string[] { "Yet another succesful build!" };
			defaults.AnotherFailure = new string[] { "The build is still broken..." };
			defaults.Fixed = new string[] { "Recent checkins have fixed the build." };
			defaults.Broken = new string[] { "Recent checkins have broken the build." };
			return defaults;
		}

		public string GetMessageForTransition(BuildTransition buildTransition)
		{
			switch (buildTransition)
			{
				case BuildTransition.StillSuccessful:
					return SelectRandomString(AnotherSuccess);
				case BuildTransition.StillFailing:
					return SelectRandomString(AnotherFailure);
				case BuildTransition.Broken:
					return SelectRandomString(Broken);
				case BuildTransition.Fixed:
					return SelectRandomString(Fixed);
			}

			throw new Exception("Unsupported build transition.");
		}

		private string SelectRandomString(string[] messages)
		{
			if (messages.Length==0)
				return "No message available.";

			int index = new Random().Next(messages.Length);
			return messages[index];
		}
	}

	#endregion

	#region Sounds

	public class Sounds
	{
		public Sound AnotherSuccessfulBuildSound;
		public Sound AnotherFailedBuildSound;
		public Sound BrokenBuildSound;
		public Sound FixedBuildSound;

		public static Sounds CreateDefaultSettings()
		{
			Sounds defaults = new Sounds();
			defaults.AnotherSuccessfulBuildSound = new Sound("extremely_well.wav");
			defaults.AnotherFailedBuildSound = new Sound("human_error.wav");
			defaults.BrokenBuildSound = new Sound("fault.wav");
			defaults.FixedBuildSound = new Sound("feeling_better.wav");
			return defaults;
		}

		#region Helper methods

		public bool ShouldPlaySoundForTransition(BuildTransition transition)
		{
			switch (transition)
			{
				case BuildTransition.Broken:
					return BrokenBuildSound.Play;

				case BuildTransition.Fixed:
					return FixedBuildSound.Play;
				
				case BuildTransition.StillFailing:
					return AnotherFailedBuildSound.Play;
				
				case BuildTransition.StillSuccessful:
					return AnotherSuccessfulBuildSound.Play;
			}

			throw new Exception("Unsupported build transition.");
		}

		public string GetAudioFileLocation(BuildTransition transition)
		{
			switch (transition)
			{
				case BuildTransition.Broken:
					return BrokenBuildSound.FileName;

				case BuildTransition.Fixed:
					return FixedBuildSound.FileName;
				
				case BuildTransition.StillFailing:
					return AnotherFailedBuildSound.FileName;
				
				case BuildTransition.StillSuccessful:
					return AnotherSuccessfulBuildSound.FileName;
			}

			throw new Exception("Unsupported build transition.");
		}


		#endregion
	}

	public class ProjectList
	{
		private Project[] projects;

		public ProjectList() {
			this.projects = new Project[0];
		}
	}

	[Serializable]
	public struct Sound
	{
		[XmlAttribute()]
		public bool Play;
		[XmlAttribute()]
		public string FileName;

		public Sound(string fileName)
		{
			Play = true;
			FileName = fileName;
		}
	}

	#endregion
}
