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

ruby_block 'update_index_html' do
  block do
    index_file = '/var/www/html/index.html'
    message = case node['ipaddress']
              when '172.31.1.65'
                '<p>Welcome to machine 1</p>'
              when '172.31.14.194'
                '<p>Welcome to machine 2</p>'
              else
                '<p>Unknown Machine</p>'
              end

    # Read index.html and insert the message inside <body>
    file_content = File.read(index_file)
    new_content = file_content.sub('</body>', "#{message}\n</body>")

    File.write(index_file, new_content)
  end
  only_if { File.exist?('/var/www/html/index.html') }
end

file '/var/www/html/machine_info.txt' do
  content lazy {
    case node['ipaddress']
    when '172.31.1.65'
      'Welcome to Production Machine'
    when '172.31.14.194'
      'Welcome to Staging Machine'
    else
      'Unknown Machine'
    end
  }
  owner 'www-data'
  group 'www-data'
  mode '0644'
  action :create
end
