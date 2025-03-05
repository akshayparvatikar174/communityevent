package 'nginx' do
  action :upgrade
end

service 'nginx' do
  action [:enable, :start]
end

['/usr/share/nginx/html', '/var/www/html'].each do |dir|
  directory dir do
    owner 'www-data'
    group 'www-data'
    mode '0755'
    action :create
    recursive true
  end
end

['/usr/share/nginx/html', '/var/www/html'].each do |dir|
  execute "clean_old_files_#{dir}" do
    command "rm -rf #{dir}/*"
    only_if { Dir.exist?(dir) }
  end
end

execute 'clone_github_repo_nginx_html' do
  command 'git clone https://github.com/akshayparvatikar174/HTMLpages.git /usr/share/nginx/html'
  not_if { File.exist?('/usr/share/nginx/html/index.html') }
end

execute 'copy_files_to_var_www_html' do
  command 'cp -r /usr/share/nginx/html/* /var/www/html/'
  only_if { File.exist?('/usr/share/nginx/html/index.html') }
end

['/usr/share/nginx/html/index.html', '/var/www/html/index.html'].each do |file|
  file file do
    owner 'www-data'
    group 'www-data'
    mode '0644'
    action :touch
  end
end

service 'nginx' do
  action :restart
end

file '/home/polyfil/sandbox.html' do
  content '<h1>Hello, Chef!</h1>'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
  only_if { node['ipaddress'] == '172.31.14.194' }
end

# Define machine-specific message
machine_message = case node['ipaddress']
                  when '172.31.1.65' then 'Welcome to Production Machine'
                  when '172.31.14.194' then 'Welcome to Staging Machine'
                  else 'Unknown Machine'
                  end

# Create machine_info.txt file with machine-specific message
file '/var/www/html/machine_info.txt' do
  content machine_message
  owner 'www-data'
  group 'www-data'
  mode '0644'
  action :create
end

# Ensure Nginx serves static files properly
file '/etc/nginx/sites-available/default' do
  content <<-CONF
server {
    listen 80;
    server_name _;
    root /var/www/html;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    location /machine_info.txt {
        default_type text/plain;
    }
}
  CONF
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

# Enable the Nginx config
execute 'enable_nginx_site' do
  command 'ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default'
  not_if { File.exist?('/etc/nginx/sites-enabled/default') }
end

# Restart Nginx to apply changes
service 'nginx' do
  action :restart
end
