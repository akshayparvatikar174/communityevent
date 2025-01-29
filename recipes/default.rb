package 'git' do
  action :install
end

package 'nginx' do
  action :install
end

service 'nginx' do
  action [:enable, :start]
end

directory '/var/www/html' do
  action :create
  recursive true
end

git '/var/www/html' do
  repository 'https://github.com/akshayparvatikar174/HTMLpages.git'
  revision 'main'
  action :sync
end

file '/var/www/html/index.html' do
  content lazy {
    ::File.read('/var/www/html/index.html')
  }
  owner 'www-data'
  group 'www-data'
  mode '0644'
  action :create
end

execute 'set_permissions' do
  command 'chown -R www-data:www-data /var/www/html'
  action :run
end

service 'nginx' do
  action :restart
end
