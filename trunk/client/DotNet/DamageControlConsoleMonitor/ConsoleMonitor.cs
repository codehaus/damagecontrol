using System;
using ThoughtWorks.DamageControl.DamageControlClientNet;

namespace ThoughtWorks.DamageControl.DamageControlConsoleMonitor
{
	/// <summary>
	/// Summary description for Class1.
	/// </summary>
	class ConsoleMonitor
	{
		Project project;
		/// <summary>
		/// The main entry point for the application.
		/// </summary>
		[STAThread]
		static void Main(string[] args)
		{
			Project project;
			if (args.Length==2)
			{
				project = new Project(args[0], args[1]);
			} 
			else 
			{
				project = new Project("http://192.168.0.2/","jira");
				project.Password = "dc";
				project.Username = "dc";
			}
			ConsoleMonitor monitor = new ConsoleMonitor(project);

			Console.ReadLine();
			Console.WriteLine("end");
			Environment.Exit(0);
		}

		public ConsoleMonitor(Project p)
		{
			project = p;
			project.OnPolled +=new PolledEventHandler(justPolled);
			project.OnError += new ErrorEventHandler(pollingError);
			project.OnBuildOccurred +=new BuildOccurredEventHandler(buildOccurred);

			project.StartPolling();
		}

		private void justPolled(object sauce, PolledEventArgs e)
		{
			Console.Write(".");
		}

		private void pollingError(object sauce, ErrorEventArgs e)
		{
			Console.WriteLine(e.Exception.Message);
		}

		private void buildOccurred(object sauce, BuildOccurredEventArgs e)
		{
			Console.WriteLine(e.ProjectStatus.BuildStatusUrl);
		}
	}
}
