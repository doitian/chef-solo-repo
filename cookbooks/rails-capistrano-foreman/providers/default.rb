action :install do
  location = new_resource.location
  formatter = new_resource.formatter

  if location.nil?
    case formatter
    when 'upstart'
      location = '/etc/init'
    when 'runit'
      location = '/etc/sv'
    else
      Chef::Application.fatal!("Require foreman export location.")
    end
  end

  application = new_resource.application
  deploy_to = new_resource.deploy_to || "/u/apps/#{application}"
  user = new_resource.user
  group = new_resource.group
  keys = new_resource.keys
  procfile = new_resource.procfile
  concurrency = new_resource.concurrency
  env = new_resource.env
  port = new_resource.port

  unless application
    Chef::Application.fatal!("rails_capistrano_foreman requires application name")
  end

  group group do
    action :create
  end

  user user do
    gid group
    home "/home/#{user}"
    shell "/bin/bash"
    supports :manage_home => true

    action :create
  end

  directory "/home/#{user}/.ssh" do
    action :create
    owner user
    group group
    mode 0760
  end

  template "/home/#{user}/.ssh/authorized_keys" do
    source 'authorized_keys.erb'
    owner user
    group group
    mode 0644
    variables :keys => keys
    action(new_resource.force_keys ? :create : :create_if_missing)
  end

  directory deploy_to do
    action :create
    owner user
    group group
    mode 0775
    recursive true
  end

  %w(releases shared shared/system shared/log shared/pids shared/foreman).each do |dir|
    directory ::File.join(deploy_to, dir) do
      action :create
      owner user
      group group
      mode 0775
      recursive true
    end
  end

  template ::File.join(deploy_to, 'shared/foreman/.env') do
    source 'env.erb'
    owner user
    group group
    mode 0640
    variables :env => env
    action :create
  end

  template ::File.join(deploy_to, 'shared/foreman/.foreman') do
    source 'foreman.erb'
    owner user
    group group
    mode 0640
    variables(:concurrency => concurrency,
              :log => ::File.join(deploy_to, 'shared/log'),
              :port => port,
              :app => application,
              :user => user,
              :deploy_to => deploy_to)
    action :create
  end

  template ::File.join(deploy_to, 'shared/foreman/Procfile') do
    source 'Procfile.erb'
    owner user
    group group
    mode 0640
    variables :procfile => procfile
    action :create
  end

  cookbook_file ::File.join(deploy_to, 'shared/foreman/Gemfile') do
    source 'Gemfile'
    owner user
    group group
    mode 0640
    action :create
  end

  template ::File.join(deploy_to, 'shared/foreman/export.sh') do
    source 'export.sh.erb'
    owner user
    group group
    mode 0640
    variables :formatter => formatter, :location => location, :deploy_to => deploy_to
    action :create
  end

  ruby_block "export #{application}" do
    block do
      Dir.chdir(::File.join(deploy_to, 'shared/foreman')) do
        require 'foreman/cli'

        options = Hash[::YAML::load_file('.foreman').collect {|k,v| [k.to_sym, v]}]
        engine = Foreman::Engine::CLI.new(options)
        engine.load_env '.env'
        engine.load_procfile 'Procfile'
        formatter = Foreman::Export.formatter(formatter)
        formatter.new(location, engine, options).export
      end
    end
  end

  if user != 'root' && formatter == 'upstart'
    sudo user do
      user user
      nopasswd true
      commands ["/sbin/stop #{application},/sbin/start #{application},/sbin/restart #{application}"]
    end
  end
end
