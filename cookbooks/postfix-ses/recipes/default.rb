#
# Cookbook Name:: postfix-ses
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
include_recipe 'postfix'
include_recipe 'cpan::bootstrap'
include_recipe 'postfix'

package 'unzip'

ses_tools_basename = ::File.basename(node['postfix_ses']['ses_tools']['url'])
src_filepath  = ::File.join(Chef::Config['file_cache_path'] || '/tmp', ses_tools_basename)

remote_file node['postfix_ses']['ses_tools']['url'] do
  source node['postfix_ses']['ses_tools']['url']
  checksum node['postfix_ses']['ses_tools']['checksum']
  path src_filepath
  backup false
end

user node['postfix_ses']['user'] do
  system true
  action :create
end

directory node['postfix_ses']['ses_tools']['home'] do
  owner 'root'
  group 0
  recursive true
end


cpan_packages = ['Digest::SHA',
                 'URI::Escape',
                 'Mozilla::CA',
                 'Bundle::LWP',
                 'LWP::Protocol::https',
                 'MIME::Base64',
                 'Crypt::SSLeay',
                 'XML::LibXML']

cpan_packages.each do |cpan_package|
  cpan_client cpan_package do
    action :install
    install_type 'cpan_module'
    user 'root'
    group 'root'
    not_if do
      File.exists?(File.join(node['postfix_ses']['ses_tools']['home'],
                             'bin/ses-send-email.pl'))
    end
  end
end

bash "unzip_ses_tools" do
  cwd ::File.dirname(src_filepath)
  code(<<-BASH)
    unzip #{ses_tools_basename} -d #{node['postfix_ses']['ses_tools']['home']}
    chown -R postfix: #{node['postfix_ses']['ses_tools']['home']}
  BASH
  not_if do
    File.exists?(File.join(node['postfix_ses']['ses_tools']['home'],
                           'bin/ses-send-email.pl'))
  end
end

template File.join(node['postfix_ses']['ses_tools']['home'], 'aws-credentials') do
  source 'aws-credentials.erb'
  owner 'root'
  group 0
  mode 00600
end

%w{main master}.each do |cfg|
  template "/etc/postfix/#{cfg}.cf" do
    source "#{cfg}.cf.erb"
    owner "root"
    group 0
    mode 00644
  end
end

service "postfix" do
  action :restart
end

