actions :install
default_action :install

attribute :location, :kind_of => String, :default => nil
attribute :formatter, :kind_of => String, :default => 'upstart'
attribute :application, :kind_of => String, :default => nil, :name_attribute => true
attribute :deploy_to, :kind_of => String, :default => nil
attribute :user, :kind_of => String, :default => 'deploy'
attribute :group, :kind_of => String, :default => 'deploy'
attribute :keys, :kind_of => Array, :default => []
attribute :force_keys, :equal_to => [true, false], :default => false
attribute :procfile, :kind_of => Hash, :default => {}
attribute :concurrency, :kind_of => String, :default => nil
attribute :env, :kind_of => Hash, :default => {}
attribute :port, :kind_of => Fixnum, :default => 5000
