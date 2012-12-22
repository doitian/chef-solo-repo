#
# Cookbook Name:: rails-capistrano-foreman
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

default_config = node['rails_capistrano_foreman']
rails_capistrano_foreman default_config['application'] do
  location default_config['location']
  formatter default_config['formatter']
  application default_config['application']
  deploy_to default_config['deploy_to']
  user default_config['user']
  group default_config['group']
  keys default_config['keys']
  force_keys default_config['force_keys']
  procfile default_config['procfile']
  concurrency default_config['concurrency']
  env default_config['env']
  port default_config['port']
end
