#
# Cookbook Name:: ubuntu_graphite_api
# Recipe:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

apt_update 'update' do
  action :update
end

package ['graphite-api', 'apache2', 'libapache2-mod-wsgi-py3', 'python-pylibmc', 'python3-pip', 'libffi-dev', 'libcairo2-dev']

bash 'python pip' do
  code <<-EOH
  pip3 install Flask-Cache
  pip3 install graphite-api[cache]
  pip3 install redis
  EOH
end

template '/etc/graphite-api.yaml' do
  source 'graphite-api.yaml.erb'
  notifies :restart, 'service[apache2]', :delayed
end

directory '/var/www/wsgi-scripts'

directory '/var/lib/graphite' do
  owner '_graphite'
  group '_graphite'
end

directory '/var/lib/graphite/whisper/' do
  owner '_graphite'
  group '_graphite'
end

file '/var/www/wsgi-scripts/graphite-api.wsgi' do
  content 'from graphite_api.app import app as application'
end

file '/var/lib/graphite-api/index' do
  action :create_if_missing
  owner '_graphite'
  group '_graphite'
end

cookbook_file '/etc/apache2/ports.conf' do
  source 'ports.conf'
  notifies :restart, 'service[apache2]', :delayed
end

cookbook_file '/etc/apache2/sites-available/apache2-graphite.conf' do
  source 'apache2-graphite.conf'
  notifies :restart, 'service[apache2]', :delayed
end

execute 'a2ensite apache2-graphite'
execute 'a2dissite 000-default.conf'

service 'apache2' do
  action :enable
end

directory '/opt/scripts'

template '/opt/scripts/cleanupGraphite.sh' do
  source 'cleanupGraphite.sh.erb'
end

cron 'cleanup script' do
  minute '0'
  hour '3'
  weekday '3'
  user '_graphite'
  command 'flock -n /tmp/cleanupGraphite.lock -c /opt/scripts/cleanupGraphite.sh'
end
