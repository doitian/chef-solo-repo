#
# Cookbook Name:: sunspot-tomcat
# Recipe:: default
#
# Follow the https://github.com/sunspot/sunspot/wiki/Configure-Solr-on-Ubuntu,-the-quickest-way

require 'sunspot/solr/installer'

include_recipe 'tomcat'

package 'solr-tomcat' do
  action :install
end
if node['platform'] == 'ubuntu' && node['platform_version'] == '12.04'
  package 'default-jre-headless' do
    action :install
  end
end

options = { :foce => true, :verbose => true }
Sunspot::Solr::Installer.execute(node['sunspot-tomcat']['conf_dir'], options)

execute "update-config-dir-ownership" do
  command "chown -R #{node["tomcat"]["user"]}:#{node["tomcat"]["group"]} #{node["sunspot-tomcat"]["conf_dir"]}"
end

service "tomcat" do
  service_name "tomcat6"
  case node["platform"]
  when "centos","redhat","fedora"
    supports :restart => true, :status => true
  when "debian","ubuntu"
    supports :restart => true, :reload => true, :status => true
  end
  action :restart
end

directory File.join(node["tomcat"]["base"], 'solr/data/index') do
  owner node["tomcat"]["user"]
  group node["tomcat"]["group"]
  recursive true
end

