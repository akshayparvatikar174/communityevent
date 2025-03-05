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
                  when '172.31.1.65' then 'Production Machine - Prod 001'
                  when '172.31.14.194' then 'Staging Machine - Stag 001'
                  else 'Unknown Machine'
                  end

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
