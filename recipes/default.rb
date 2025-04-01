# Upgrade the 'nginx' package to the latest available version
package 'nginx' do
  action :upgrade
end

# Ensure Git is installed before cloning the repository
package 'git' do
  action :install
end

# Enable and start the Nginx service to ensure it runs at boot
service 'nginx' do
  action [:enable, :start]
end

# Ensure required directories exist
['/usr/share/nginx/html', '/var/www/html'].each do |dir|
  directory dir do
    owner 'www-data'
    group 'www-data'
    mode '0755'
    action :create
    recursive true
  end
end

# Clean old files before cloning
['/usr/share/nginx/html', '/var/www/html'].each do |dir|
  execute "clean_old_files_#{dir}" do
    command "rm -rf #{dir}/*"
    only_if { Dir.exist?(dir) && Dir.entries(dir).size > 2 }
  end
end

# Clone the GitHub repository
execute 'clone_github_repo_nginx_html' do
  command 'git clone https://github.com/akshayparvatikar174/HTMLpages.git /usr/share/nginx/html'
  not_if { File.exist?('/usr/share/nginx/html/index.html') }
  retries 3
  retry_delay 5
end

# Ensure correct permissions for the cloned files
execute 'fix_permissions_for_nginx_html' do
  command 'chown -R www-data:www-data /usr/share/nginx/html && chmod -R 755 /usr/share/nginx/html'
end

# Copy files to /var/www/html
execute 'copy_files_to_var_www_html' do
  command 'cp -r /usr/share/nginx/html/* /var/www/html/'
  only_if { File.exist?('/usr/share/nginx/html/index.html') }
end

# Ensure correct permissions for /var/www/html
execute 'fix_permissions_for_var_www_html' do
  command 'chown -R www-data:www-data /var/www/html && chmod -R 755 /var/www/html'
end

# Define machine-specific message based on IP address
machine_message = case node['ipaddress']
                  when '54.219.227.136' then 'Production Machine - Prod 001'
                  else 'Unknown Machine'
                  end

# Verify that the machine message is correctly assigned
log 'machine_message' do
  message "Machine message: #{machine_message}"
  level :info
end

# Ensure the directory for Nginx site configuration exists
directory '/etc/nginx/sites-enabled' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

# Create or modify the Nginx site configuration
file '/etc/nginx/sites-enabled/default' do
  content <<-EOF
server {
    listen 80;
    server_name _;

    location / {
        root /var/www/html;
        index index.html;
        sub_filter '{{MACHINE_MESSAGE}}' '#{machine_message}';  # Replace placeholder with actual message
        sub_filter_once off;  # Ensure it replaces all instances of the placeholder
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

# Create a sandbox HTML file only on a specific machine (IP: 172.31.13.182)
file '/home/polyfil/sandbox.html' do
  content '<h1>Hello, Chef!</h1>'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
  only_if { node['ipaddress'] == '172.31.13.182' }
end

# Restart Nginx service to apply changes
service 'nginx' do
  action :restart
end
