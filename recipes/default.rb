execute 'update_package_list' do
  command 'apt update -y'
end

# Install the latest version of Nginx
package 'nginx' do
  action :upgrade
end

service 'nginx' do
  action [:enable, :start]
end

directory '/usr/share/nginx/html' do
  owner 'www-data'
  group 'www-data'
  mode '0755'
  action :create
  recursive true
end

execute 'clean_old_files' do
  command 'rm -rf /usr/share/nginx/html/*'
  only_if { Dir.exist?('/usr/share/nginx/html') }
end

execute 'clone_github_repo' do
  command 'git clone https://github.com/akshayparvatikar174/HTMLpages.git /usr/share/nginx/html'
  not_if { File.exist?('/usr/share/nginx/html/index.html') }
end

file '/usr/share/nginx/html/index.html' do
  owner 'www-data'
  group 'www-data'
  mode '0644'
  action :touch
end

service 'nginx' do
  action :restart
end
