// project created on 11/5/2004 at 9:19 PM
using System;
using System.Collections;
using System.IO;
using System.Xml.Serialization;
using ThoughtWorks.DamageControl.DamageControlClientNet;

namespace ThoughtWorks.DamageControl.MonoTray {

	public class MonoTray
	{
			
	        public static void Main (string[] args)
	        {
	                new DamageControlTrayIcon();
	        }
	        
	        public static void SaveProjects(ArrayList settings)
		    {
		         string SettingsPathAndFileName = System.Environment.GetEnvironmentVariable("HOME") + "/.dctraymono";
			     Console.WriteLine("Writing settings");
    			 DamageControlSettings s = new DamageControlSettings();
	       		 s.Projects = settings;
	       		TextWriter writer = null;
	       		try
	       		{
	       			XmlSerializer serializer = new XmlSerializer(typeof(DamageControlSettings));
	       			writer = new StreamWriter(SettingsPathAndFileName);
	       			serializer.Serialize(writer, s);
	       		}
	       		finally
	       		{
	       			if (writer!=null)
	       				writer.Close();
	       		}
	       }
	       
	       public static ArrayList LoadSettings()
		{
			Console.WriteLine("Loading settings");
			string SettingsPathAndFileName = System.Environment.GetEnvironmentVariable("HOME") + "/.dctraymono";
			if (!File.Exists(SettingsPathAndFileName))
			{
				return new ArrayList();
			}

			// file exists, so deserialise it
			TextReader reader = null;
			try 
			{
				XmlSerializer serializer = new XmlSerializer(typeof(DamageControlSettings));
				reader = new StreamReader(SettingsPathAndFileName);
				DamageControlSettings settings = (DamageControlSettings)serializer.Deserialize(reader);
				return settings.Projects;
			} 
			catch 
			{
				return new ArrayList();
			}
			finally
			{
				if (reader!=null)
					reader.Close();
			}
		}
	}
	
	[XmlRootAttribute("DamageControlMonitor", Namespace="http://damagecontrol.codehaus.org", IsNullable=false)]
	public class DamageControlSettings
	{
	   [System.Xml.Serialization.XmlArray("Projects")]
	   [System.Xml.Serialization.XmlArrayItem("project",typeof(Project))]
	   public ArrayList Projects;
	   public DamageControlSettings() {}
	}

}

