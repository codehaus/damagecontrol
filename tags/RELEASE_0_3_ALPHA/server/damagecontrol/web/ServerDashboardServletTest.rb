module DamageControl
  class ServerDashboardServletTest
    def test_default_displays_all_projects
      pcr = ProjectConfigRepository.new
      bhr = BuildHistoryRepository.new
      servlet = ServerDashboardServlet.new(pcr, bhr)
      servlet.dashboard()
    end
  end
end