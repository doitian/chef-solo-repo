require 'bundler/capistrano'
set :bundle_without, [:deployment]
set :bundle_flags, '--binstubs --quiet --deployment'

default_run_options[:pty] = true

depend :remote, :command, 'ruby'

ssh_options[:forward_agent] = true
set :application, "chef-solo-repo"

set :scm, :git

# Package the repository and upload to server
set :repository,  ".git"
set :deploy_via, :copy
set :copy_cache, true
set :checkout, 'export'
set :copy_exclude, ['.git/*', 'vendor/*']

# Or deploy via git server
# set :repository,  "git@github.com:doitian/chef-solo-repo.git"
# set :checkout, 'export'
# set :deploy_via, :remote_cache

set :branch, 'master'
set :keep_releases, 2
set :user, "ubuntu"
set :use_sudo, true

class ServerDSL
  def initialize(f)
    @options = {}
    eval(File.read(f))
  end
  def node
    @node ||= FakeNode.new
  end
  def method_missing(name, *args)
    args.size == 0 ? @options[name] : @options[name] = args.first
  end

  class FakeNode
    def [](*args); end
    def []=(*args); end
    def set(*args); self; end
    alias_method :normal, :set
    alias_method :default, :set
    alias_method :override, :set
  end
end

on :load do
  ARGV.each do |arg|
    if arg =~ /^servers\/.+\.rb$/
      s = ServerDSL.new(arg)
      server s.host, :app, :user => s.user, :port => s.port, :ssh_options => s.ssh_options
    end
  end
end

Dir[File.expand_path('../../servers/*.rb', __FILE__)].each do |f|
  relative_filename = 'servers/' + File.basename(f)
  desc "Deploy to #{File.basename(relative_filename).sub(/\.rb$/, '')}"
  task relative_filename do
    # place holder to eat missing task error, the file has been loaded in
    # on :load block
  end
end

task :inspect_servers do
  p find_servers
end

namespace :deploy do
  task :default do
    update
    top.chef.default
  end
  task :symlink_cache_dir do
    run ["mkdir -p #{shared_path}/cache",
         "ln -sfn #{shared_path}/cache #{current_release}/.chef/solo/cache"].join(' && ')
  end
  task :setup_directory_owner do
    run "#{try_sudo} chown -R $USER: #{deploy_to}"
  end
end

namespace :chef do
  task :inspect_json do
    find_servers_for_task(current_task).each do |s|
      system("bundle exec thor 'server:#{s.host}'")
    end
  end

  task :generate_json do
    run "cd #{current_release} && bundle exec thor 'server:$CAPISTRANO:HOST$'"
  end

  task :default do
    generate_json
    cmd = ["cd #{current_release}",
           "bin/chef-solo -c solo.rb -j json/servers/$CAPISTRANO:HOST$.json -l info"].join(' && ')
    run "#{try_sudo} bash -l -c '#{cmd}'"
  end
end

after 'deploy:setup', 'deploy:setup_directory_owner'
after 'deploy:update', 'deploy:symlink_cache_dir'
after 'deploy', 'deploy:cleanup'
