using System;

namespace ThoughtWorks.DamageControl.DamageControlClientNet
{
	public enum BuildStatus
	{
		Idle,
		Successful,
		Failed,
		Queued,
		Building,
		Killed,
		DeterminingChangesets,
		CheckingOut
	}

	public class ProjectStatus
	{
		private readonly int lastCompletedBuildDuration;
		private string projectName;

		private BuildStatus lastCompletedBuildStatus;
		private string lastCompletedBuildUrl;
		private DateTime lastCompletedBuildDate;
		private string lastCompletedBuildLabel;

		private BuildStatus currentBuildStatus;

		public ProjectStatus()
		{
			this.projectName = null;
			this.currentBuildStatus = BuildStatus.Idle;
			this.lastCompletedBuildUrl = "";
			this.lastCompletedBuildDate = DateTime.MinValue;
			this.lastCompletedBuildLabel = "Unknown - never polled";
		}

		public ProjectStatus(string projectName, BuildStatus currentBuildStatus, BuildStatus lastCompletedBuildStatus, string lastCompletedBuildUrl, DateTime lastCompletedBuildDate, string lastCompletedBuildLabel, int lastCompletedBuildDuration)
		{
			this.projectName = projectName;
			this.currentBuildStatus = currentBuildStatus;
			this.lastCompletedBuildStatus = lastCompletedBuildStatus;
			this.lastCompletedBuildUrl = lastCompletedBuildUrl;
			this.lastCompletedBuildDate = lastCompletedBuildDate;
			this.lastCompletedBuildLabel = lastCompletedBuildLabel;
			this.lastCompletedBuildDuration = lastCompletedBuildDuration;
		}

		public string Name
		{
			get { return projectName; }
		}

		public string BuildStatusUrl
		{
			get { return lastCompletedBuildUrl; }
		}

		public DateTime LastBuildDate
		{
			get { return lastCompletedBuildDate; }
		}

		public BuildStatus BuildStatus
		{
			get { return lastCompletedBuildStatus; }
		}

		public BuildStatus CurrentBuildStatus
		{
			get { return currentBuildStatus; }
		}

		public string LastBuildLabel
		{
			get { return lastCompletedBuildLabel; }
		}

		public String DurationAsString
		{
			get
			{
				TimeSpan span = new TimeSpan(0, 0, lastCompletedBuildDuration);
				return span.ToString();
			}
		}
	}
}