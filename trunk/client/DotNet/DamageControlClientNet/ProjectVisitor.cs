using System;
using ThoughtWorks.DamageControl.DamageControlClientNet;

namespace DamageControlClientNet
{
	public interface ProjectVisitor
	{
		void visitProject(Project project);
	}
}
