PLUGINS_DIR = File.expand_path(File.dirname(__FILE__) + '/../../vendor/plugins')

desc "Copy third-party gems into ./vendor"
task :freeze_other_gems do
  require 'rubygems'
  require 'yaml'

  gem_names = YAML.load_file(File.dirname(__FILE__) + '/gems.yml')
  gem_names.each do |gem_name|
    gem = Gem.cache.search(gem_name).sort_by { |g| g.version }.last
    system "cd #{PLUGINS_DIR}; gem unpack -v '#{gem.version}' #{gem.name};"
  end
end

desc "Installs third-party gems"
task :install_gems do
  require 'rubygems'
  require 'yaml'

  gem_names = YAML.load_file(File.dirname(__FILE__) + '/gems.yml')
  gem_names.each do |gem_name|
    system "gem install --no-rdoc --no-test --include-dependencies #{gem_name}"
  end
end
