using System;
using System.Reflection;

namespace ThoughtWorks.DamageControl.DamageControlClientNet
{
	public enum BuildTransition
	{
		[BuildTransition("Build Broken", ErrorLevel.Error)]
		Broken,

		[BuildTransition("Build Fixed", ErrorLevel.Info)]
		Fixed,

		[BuildTransition("Build Successful", ErrorLevel.Info)]
		StillSuccessful,

		[BuildTransition("Build Still Broken", ErrorLevel.Warning)]
		StillFailing
	}

	public enum ErrorLevel
	{
		Info,
		Warning,
		Error
	}

	public class BuildTransitionAttribute : Attribute
	{
		public string Caption;
		public ErrorLevel ErrorLevel;

		public BuildTransitionAttribute(string caption, ErrorLevel messageType)
		{
			Caption = caption;
			ErrorLevel = messageType;
		}
	}

	internal class BuildTransitionUtil
	{
		public static BuildTransitionAttribute GetBuildTransitionAttribute(BuildTransition transition)
		{
			FieldInfo fieldInfo = transition.GetType().GetField(transition.ToString());
			BuildTransitionAttribute[] attributes = 
				(BuildTransitionAttribute[])fieldInfo.GetCustomAttributes(typeof(BuildTransitionAttribute), false);
			return (attributes.Length>0) ? attributes[0] : null;
		}
	}
}
