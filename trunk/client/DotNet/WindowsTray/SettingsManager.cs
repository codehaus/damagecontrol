using System;
using System.IO;
using System.Xml.Serialization;

namespace ThoughtWorks.DamageControl.WindowsTray
{
	/// <summary>
	/// Utility class for managing DamageControl Monitor settings.
	/// </summary>
	public class SettingsManager
	{
		#region Private constructor

		/// <summary>
		/// Utility class, not intended for instantiation.
		/// </summary>
		private SettingsManager()
		{ }

		#endregion

		#region Settings file name location

		private const string DEFAULT_SETTINGS_FILE = "dctray-settings.xml";

		static private string _settingsFileName = DEFAULT_SETTINGS_FILE;

		/// <summary>
		/// The filename of the settings file to be used by the executing application.
		/// </summary>
		static public string SettingsFileName
		{
			set
			{
				_settingsFileName = value;
			}
		}
		
		private static bool _hasnewsettings = true;
		static public bool HasNewSettings
		{
			get
			{
				return _hasnewsettings;
			}
		}

		/// <summary>
		/// Gets the absolute path and filename to the settings file to be used
		/// by the executing application.
		/// </summary>
		static private string SettingsPathAndFileName
		{
			get
			{
				return Path.Combine(AppDomain.CurrentDomain.BaseDirectory, _settingsFileName);
			}
		}

		#endregion

		#region Read and write settings

		/// <summary>
		/// Writes the specified settings using Xml serialisation.
		/// </summary>
		/// <param name="settings">The settings to write.</param>
		public static void WriteSettings(Settings settings)
		{
			Console.WriteLine("Writing settings");
			TextWriter writer = null;
			try
			{
				XmlSerializer serializer = new XmlSerializer(typeof(Settings));
				writer = new StreamWriter(SettingsPathAndFileName);
				serializer.Serialize(writer, settings);
			}
			finally
			{
				if (writer!=null)
					writer.Close();
			}
		}

		/// <summary>
		/// Loads and returns the settings to be used, via Xml deserialisation.
		/// </summary>
		/// <returns>The deserialised settings.</returns>
		public static Settings LoadSettings()
		{
			Console.WriteLine("Loading settings");
			if (!File.Exists(SettingsPathAndFileName))
			{
				Settings defaults = Settings.CreateDefaultSettings();
				WriteSettings(defaults);
				_hasnewsettings = true;
				return defaults;
			}

			// file exists, so deserialise it
			TextReader reader = null;
			try 
			{
				XmlSerializer serializer = new XmlSerializer(typeof(Settings));
				reader = new StreamReader(SettingsPathAndFileName);
				_hasnewsettings = false;
				return (Settings)serializer.Deserialize(reader);
			} 
			catch 
			{
				Settings defaults = Settings.CreateDefaultSettings();
				WriteSettings(defaults);
				_hasnewsettings = true;
				return defaults;
			}
			finally
			{
				if (reader!=null)
					reader.Close();
			}
		}

		#endregion
	}
}
