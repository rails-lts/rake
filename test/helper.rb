require 'rubygems'
$:.unshift File.expand_path('../../lib', __FILE__)

begin
  gem 'minitest', '~> 5'
rescue Gem::LoadError
end

require 'minitest/autorun'
require 'rake'
require 'tmpdir'
require File.expand_path('../file_creation', __FILE__)

require_relative 'support/ruby_runner'
require_relative 'support/rakefile_definitions'

class Rake::TestCase < Minitest::Test
  include FileCreation

  include Rake::DSL

  class TaskManager
    include Rake::TaskManager
  end

  RUBY = Gem.ruby

  def setup
    ARGV.clear

    @verbose = ENV['VERBOSE']

    @rake_root = File.expand_path '../../', __FILE__
    @rake_exec = File.join @rake_root, 'exe', 'rake'
    @rake_lib  = File.join @rake_root, 'lib'
    @ruby_options = ["-I#{@rake_lib}", "-I."]

    @orig_pwd = Dir.pwd
    @orig_appdata      = ENV['APPDATA']
    @orig_home         = ENV['HOME']
    @orig_homedrive    = ENV['HOMEDRIVE']
    @orig_homepath     = ENV['HOMEPATH']
    @orig_rake_columns = ENV['RAKE_COLUMNS']
    @orig_rake_system  = ENV['RAKE_SYSTEM']
    @orig_rakeopt      = ENV['RAKEOPT']
    @orig_userprofile  = ENV['USERPROFILE']
    ENV.delete 'RAKE_COLUMNS'
    ENV.delete 'RAKE_SYSTEM'
    ENV.delete 'RAKEOPT'

    tmpdir = Dir.chdir Dir.tmpdir do Dir.pwd end
    @tempdir = File.join tmpdir, "test_rake_#{$$}"

    FileUtils.mkdir_p @tempdir

    Dir.chdir @tempdir

    Rake.application = Rake::Application.new
    Rake::TaskManager.record_task_metadata = true
    RakeFileUtils.verbose_flag = false
  end

  def teardown
    Dir.chdir @orig_pwd
    FileUtils.rm_rf @tempdir

    if @orig_appdata
      ENV['APPDATA'] = @orig_appdata
    else
      ENV.delete 'APPDATA'
    end

    ENV['HOME']         = @orig_home
    ENV['HOMEDRIVE']    = @orig_homedrive
    ENV['HOMEPATH']     = @orig_homepath
    ENV['RAKE_COLUMNS'] = @orig_rake_columns
    ENV['RAKE_SYSTEM']  = @orig_rake_system
    ENV['RAKEOPT']      = @orig_rakeopt
    ENV['USERPROFILE']  = @orig_userprofile
  end

  def ignore_deprecations
    Rake.application.options.ignore_deprecate = true
    yield
  ensure
    Rake.application.options.ignore_deprecate = false
  end

  def rake_system_dir
    @system_dir = 'system'

    FileUtils.mkdir_p @system_dir

    open File.join(@system_dir, 'sys1.rake'), 'w' do |io|
      io << <<-SYS
task "sys1" do
  puts "SYS1"
end
      SYS
    end

    ENV['RAKE_SYSTEM'] = @system_dir
  end

  def rakefile(contents)
    open 'Rakefile', 'w' do |io|
      io << contents
    end
  end

  def jruby?
    defined?(JRUBY_VERSION)
  end

  def jruby17?
    jruby? && (JRUBY_VERSION < '9.0.0.0')
  end

  def jruby9?
    jruby? && (JRUBY_VERSION >= '9.0.0.0')
  end

  include RakefileDefinitions
end
