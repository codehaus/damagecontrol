require 'gplot/Gnuplot'
require 'damagecontrol/core/Build'
require 'damagecontrol/core/BuildHistoryRepository'
require 'damagecontrol/core/ProjectDirectories'
require 'pebbles/TimeUtils'

module DamageControl
module Tool
module Plot

  class BuildHistoryReportGenerator
    TIME_FORMAT = "%Y/%m/%d"
  
    def initialize(build_history_repository)
      @build_history_repository = build_history_repository
    end

    def generate(dir, project_name)
      generate_build_duration_by_date(dir, project_name, :week)
      generate_build_duration_by_build(dir, project_name, :week)
      generate_builds_per_period_graph(dir, project_name, :week)
    end

    def generate_build_duration_by_date(dir, project_name, period)
      builds_per_period_map, x_dates, number_of_periods, first_period_number, first_period, last_period = generate_skeleton(project_name, period)

      build_durations_by_start_time = {}
      builds_per_period_map.each do |period_start, builds|
        builds.each do |build|
          if(build.status == DamageControl::Build::SUCCESSFUL)
            build_duration = build.end_time - build.start_time
            build_durations_by_start_time[Time.at(build.start_time).utc] = build_duration
          end
        end
      end
      sorted_builds = build_durations_by_start_time.sort
      
      x_dates = []
      build_duration_per_successful_build_array = []
      sorted_builds.each do |start_time_duration|
        start_time = start_time_duration[0].utc.strftime(TIME_FORMAT)
        x_dates << "#{start_time}"
        build_duration_per_successful_build_array << "#{start_time_duration[1]}"
      end
      
      # Run gnuplot

      plot = Gnuplot::Plot.new("date.plot")
      plot.title "#{project_name} build durations (by #{period.id2name})" 
      plot.xlabel "Date"
      plot.ylabel "Build duration (seconds)"
      plot.term "png small"
      plot.grid
      plot.output "#{dir}/build_duration_by_#{period.id2name}.png"

      plot.xdata "time"
      plot.timefmt "\#{TIME_FORMAT}\""
      plotstart = first_period.strftime(TIME_FORMAT)
      plotend = last_period.strftime(TIME_FORMAT)
      plot.xrange "\"#{plotstart}\"", "\"#{plotend}\""
      plot.yrange "0", ""
      plot.format "x \"#{TIME_FORMAT}\""
#      plot.data "style linespoints"

      build_duration_per_successful_build_ds = build_duration_per_successful_build_array.gpds("title"=>"Build duration for successful builds", "xgrid"=>x_dates, "using"=>"1:2")

      plot.draw(build_duration_per_successful_build_ds)
    end

    def generate_build_duration_by_build(dir, project_name, period)
      builds_per_period_map, x_dates, number_of_periods, first_period_number, first_period, last_period = generate_skeleton(project_name, period)

      build_durations_by_start_time = {}
      builds_per_period_map.each do |period_start, builds|
        builds.each do |build|
          if(build.status == DamageControl::Build::SUCCESSFUL)
            build_duration = build.end_time - build.start_time
            build_durations_by_start_time[Time.at(build.start_time).utc] = build_duration
          end
        end
      end
      sorted_builds = build_durations_by_start_time.sort
      
      x_values = []
      i = 0
      build_duration_per_successful_build_array = []
      sorted_builds.each do |start_time_duration|
        start_time = start_time_duration[0].utc.strftime(TIME_FORMAT)
        x_values << i.to_s
        build_duration_per_successful_build_array << "#{start_time_duration[1]}"
        i += 1
      end
      
      # Run gnuplot

      plot = Gnuplot::Plot.new("build.plot")
      plot.title "#{project_name} build durations (by build #)" 
      plot.xlabel "Build #"
      plot.ylabel "Build duration (seconds)"
      plot.term "png small"
      plot.grid
      plot.output "#{dir}/build_duration_by_build.png"

      plot.yrange "0", ""
      plot.data "style linespoints"

      build_duration_per_successful_build_ds = build_duration_per_successful_build_array.gpds("title"=>"Build duration for successful builds", "xgrid"=>x_values, "using"=>"1:2")

      plot.draw(build_duration_per_successful_build_ds)
    end

    def generate_builds_per_period_graph(dir, project_name, period)
      builds_per_period_map, x_dates, number_of_periods, first_period_number, first_period, last_period = generate_skeleton(project_name, period)

      # Build the values for successful, failed and total

      successful_builds_per_period_array = Array.new(number_of_periods, 0)
      failed_builds_per_period_array = Array.new(number_of_periods, 0)
      total_builds_per_period_array = Array.new(number_of_periods, 0)

      builds_per_period_map.each do |period_start, builds|
        week_number, start = period_start.get_period_info(:week)
        week_index = week_number - first_period_number
        
        successful_builds = 0
        failed_builds = 0
        builds.each do |build|
          successful_builds += 1 if build.status == Build::SUCCESSFUL
          failed_builds += 1 if build.status == Build::FAILED
        end

        successful_builds_per_period_array[week_index] = successful_builds
        failed_builds_per_period_array[week_index] = failed_builds
        total_builds_per_period_array[week_index] = successful_builds + failed_builds
      end

      # Run gnuplot

      plot = Gnuplot::Plot.new("freq.plot")
      plot.title "#{project_name} builds per #{period.id2name}" 
      plot.xlabel "Date"
      plot.ylabel "Number of builds"
      plot.term "png small"
      plot.grid
      plot.output "#{dir}/builds_per_#{period.id2name}.png"

      plot.xdata "time"
      plot.timefmt "\"#{TIME_FORMAT}\""
      plotstart = first_period.strftime(TIME_FORMAT)
      plotend = last_period.strftime(TIME_FORMAT)
      plot.xrange "\"#{plotstart}\"", "\"#{plotend}\""
      plot.yrange "0", ""
      plot.format "x \"#{TIME_FORMAT}\""
      plot.data "style linespoints"

      successful_builds_per_week_ds = successful_builds_per_period_array.gpds("with"=>"filledcurve x2 lt 15", "title"=>"Successful builds", "xgrid"=>x_dates, "using"=>"1:2")
      failed_builds_per_week_ds = failed_builds_per_period_array.gpds("title"=>"Failed builds", "xgrid"=>x_dates, "using"=>"1:2")
      total_builds_per_week_ds = total_builds_per_period_array.gpds("title"=>"Total builds", "xgrid"=>x_dates, "using"=>"1:2")

      plot.draw(failed_builds_per_week_ds, successful_builds_per_week_ds, total_builds_per_week_ds)
    end

    def generate_skeleton(project_name, period)
      builds_per_period_map = @build_history_repository.group_by_period(project_name, period)    
      
      first_period = nil
      last_period = nil
      builds_per_period_map.each do |period_start, builds|
        first_period = period_start if first_period.nil? || period_start < first_period
        last_period = period_start if last_period.nil? || period_start > last_period
      end
      
      first_period_number, start = first_period.get_period_info(:week)

      number_of_periods = (last_period-first_period) / (7 * 24 * 60 * 60) + 1

      # Create the x axis

      x_dates = Array.new(number_of_periods)
      i = 0
      x_dates.each{
        period_timestamp = first_period + (i * 7 * 24 * 60 * 60)
        x_dates[i] = Time.at(period_timestamp).utc.strftime("%y/%m/%d")
        i = i+1
      }
puts first_period
puts last_period
      return builds_per_period_map, x_dates, number_of_periods, first_period_number, first_period, last_period
    end

  end

end
end
end

if __FILE__ == $0
  require 'damagecontrol/util/FileUtils'
  include FileUtils
  root = File.expand_path("#{damagecontrol_home}/testdata/testroot")
  pd = DamageControl::ProjectDirectories.new(root)
  bhr = DamageControl::BuildHistoryRepository.new(nil, pd)
  r = DamageControl::Tool::Plot::BuildHistoryReportGenerator.new(bhr)
  r.generate(".", "picocontainer")
end