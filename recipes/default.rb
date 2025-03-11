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

# Define a message based on the machine's IP address
machine_message = case node['ipaddress']
                  when '172.31.15.184' then 'Production Machine - Prod 001'
                  when '172.31.13.182' then 'Staging Machine - Stag 001'
                  when '172.31.12.220' then 'Staging Machine - Stag 002'
                  else 'Unknown Machine'
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

# Replace the placeholder '{{MACHINE_MESSAGE}}' in index.html with the actual machine message
ruby_block 'replace_machine_message' do
  block do
    file_path = '/var/www/html/index.html'
    
    if File.exist?(file_path)
      content = File.read(file_path)

      # Debugging: Print current content (Optional)
      puts "Current index.html content: #{content}" 

      if content.include?('{{MACHINE_MESSAGE}}')
        new_content = content.gsub('{{MACHINE_MESSAGE}}', machine_message)
        File.write(file_path, new_content)
        puts "Updated index.html with: #{machine_message}"
      else
        puts "Placeholder not found in index.html!"
      end
    else
      puts "File /var/www/html/index.html does not exist!"
    end
  end
  action :run
end

# Restart Nginx to apply changes
service 'nginx' do
  action :restart
end
