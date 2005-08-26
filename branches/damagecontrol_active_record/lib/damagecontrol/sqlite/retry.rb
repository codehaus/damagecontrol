class ActiveRecord::ConnectionAdapters::AbstractAdapter
  # Expose connection. We need to set the busy_handler
  attr_reader :connection
end

# Make SQLite retry if the database is busy.
sqlite = ActiveRecord::Base.connection.connection
sqlite.busy_timeout(5000)
sqlite.busy_handler do |resource, retries|
  STDERR.puts "SQLite is busy, busy, busy: #{resource}, #{retries}"
  true
end
