using System;
using System.Xml.Serialization;

namespace ThoughtWorks.DamageControl.DCTray
{
	/// <summary>
	/// Encapsulates all user-settings for the DamageControl Monitor.  This class
	/// is designed to work with Xml serialisation, for persisting user settings.
	/// </summary>
	[XmlRootAttribute("DamageControlMonitor", Namespace="http://damagecontrol.codehaus.org", IsNullable=false)]
	public class Settings
	{
		public int PollingIntervalSeconds;
		public string RemoteServerUrl;

		public string ProjectName;

		public NotificationBalloon NotificationBalloon;

		public Sounds Sounds = new Sounds();

		public Messages Messages = new Messages();

		public ConnectionMethod ConnectionMethod;

		public bool ShowExceptions = true;

		public Settings()
		{
		}

		public static Settings CreateDefaultSettings()
		{
			Settings defaults = new Settings();

			defaults.ProjectName = "ProjectName";

			defaults.ConnectionMethod = ConnectionMethod.Remoting;
			defaults.ShowExceptions = true;

			defaults.Sounds = Sounds.CreateDefaultSettings();
			defaults.NotificationBalloon = NotificationBalloon.CreateDefaultSettings();
			defaults.Messages = Messages.CreateDefaultSettings();

			defaults.PollingIntervalSeconds = 15;
			defaults.RemoteServerUrl = "http://localhost:4712/public/xmlrpc";

			return defaults;
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
			defaults.AnotherSuccessfulBuildSound = new Sound("still-successful.wav");
			defaults.AnotherFailedBuildSound = new Sound("still-failing.wav");
			defaults.BrokenBuildSound = new Sound("broken.wav");
			defaults.FixedBuildSound = new Sound("fixed.wav");
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

	[Serializable]
	public struct Sound
	{
		[XmlAttribute()]
		public bool Play;
		[XmlAttribute()]
		public string FileName;

		public Sound(string fileName)
		{
			Play = false;
			FileName = fileName;
		}
	}

	#endregion
}
