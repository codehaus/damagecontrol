using System;

namespace ThoughtWorks.DamageControl.DamageControlClientNet
{
	public enum BuildStatus
	{
		Unknown, Success, Failure, Nothing, Working
	}

	public class ProjectStatus
	{
		string projectName;
		BuildStatus currentBuildStatus;
		BuildStatus buildStatus;
		string buildStatusUrl;
		DateTime lastBuildDate;
		string lastBuildLabel;
		public ProjectStatus()
		{
			this.projectName = null;
			this.currentBuildStatus = BuildStatus.Unknown;
			this.buildStatusUrl = "";
			this.lastBuildDate = DateTime.MinValue;
			this.lastBuildLabel = "Unknown - never polled";
		}

		public ProjectStatus(string projectName, BuildStatus currentBuildStatus, BuildStatus buildStatus, string buildStatusUrl, DateTime lastBuildDate, string lastBuildLabel)
		{
			this.projectName = projectName;
			this.currentBuildStatus = currentBuildStatus;
			this.buildStatus = buildStatus;
			this.buildStatusUrl = buildStatusUrl;
			this.lastBuildDate = lastBuildDate;
			this.lastBuildLabel = lastBuildLabel;
		}

		public string Name
		{
			get
			{
				return projectName;
			}
		}

		public string BuildStatusUrl
		{
			get 
			{
				return buildStatusUrl;
			}
		}

		public DateTime LastBuildDate
		{
			get
			{
				return lastBuildDate;
			}
		}

		public BuildStatus BuildStatus 
		{
			get
			{
				return buildStatus;
			}
		}

		public BuildStatus CurrentBuildStatus 
		{
			get
			{
				return currentBuildStatus;
			}
		}

		public string LastBuildLabel
		{
			get
			{
				return lastBuildLabel;
			}
		}
	}
}
