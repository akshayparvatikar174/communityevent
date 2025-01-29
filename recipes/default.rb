package 'nginx'
package 'git'

service 'nginx' do
  action [:enable, :start]
end

directory '/var/www/html' do
  owner 'www-data'
  group 'www-data'
  mode '0755'
  action :create
  recursive true
end

execute 'clean_old_files' do
  command 'rm -rf /var/www/html/*'
  only_if { Dir.exist?('/var/www/html') }
end

execute 'clone_github_repo' do
  command 'git clone https://github.com/akshayparvatikar174/HTMLpages.git /var/www/html'
  not_if { File.exist?('/var/www/html/index.html') }
end

file '/var/www/html/index.html' do
  owner 'www-data'
  group 'www-data'
  mode '0644'
  action :touch
end

service 'nginx' do
  action :restart
end
