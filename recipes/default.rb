# Upgrade the 'nginx' package to the latest available version
package 'nginx' do
  action :upgrade
end

# Enable and start the Nginx service to ensure it runs at boot and is currently active
service 'nginx' do
  action [:enable, :start]
end

# Define an array of directories that should exist for serving web content
['/usr/share/nginx/html', '/var/www/html'].each do |dir|
  directory dir do
    owner 'www-data'
    group 'www-data'
    mode '0755'
    action :create
    recursive true
  end
end

# Clean old files in the specified directories to ensure a fresh deployment
['/usr/share/nginx/html', '/var/www/html'].each do |dir|
  execute "clean_old_files_#{dir}" do
    command "rm -rf #{dir}/*"
    only_if { Dir.exist?(dir) }
  end
end

# Clone the GitHub repository containing HTML files into the Nginx root directory
execute 'clone_github_repo_nginx_html' do
  command 'git clone https://github.com/akshayparvatikar174/HTMLpages.git /usr/share/nginx/html'
  not_if { File.exist?('/usr/share/nginx/html/index.html') }
end

# Copy files from /usr/share/nginx/html to /var/www/html to keep both directories in sync
execute 'copy_files_to_var_www_html' do
  command 'cp -r /usr/share/nginx/html/* /var/www/html/'
  only_if { File.exist?('/usr/share/nginx/html/index.html') }
end

# Ensure the index.html file has correct ownership and permissions in both locations
['/usr/share/nginx/html/index.html', '/var/www/html/index.html'].each do |file|
  file file do
    owner 'www-data'
    group 'www-data'
    mode '0644'
    action :touch
  end
end

# Restart Nginx service to apply changes
service 'nginx' do
  action :restart
end

# Create a sandbox HTML file only on a specific machine (IP: 172.31.13.182)
file '/home/polyfil/sandbox.html' do
  content '<h1>Hello, Chef!</h1>'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
  only_if { node['ipaddress'] == '172.31.13.182' }
end

# Configure Nginx to serve files from /var/www/html and enable directory listing for /home/polyfil
file '/etc/nginx/sites-enabled/default' do
  content <<-EOF
server {
    listen 80;
    server_name _;

    location / {
        root /var/www/html;
        index index.html;
    }

    location /file-list {
        alias /home/polyfil;
        autoindex on;
        autoindex_exact_size off;
        autoindex_format json;
        default_type application/json;
    }
}
  EOF
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[nginx]', :immediately
end

# Restart Nginx to apply changes
service 'nginx' do
  action :restart
end
