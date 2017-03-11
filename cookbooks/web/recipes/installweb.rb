package 'httpd'

package 'php'

package 'php-mysql'

package 'mysql'

service 'httpd' do
  action [:enable, :start]
end

bash 'open port' do
  code <<-EOH
  iptables -I INPUT 5 -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
  service iptables save
  EOH
end

cookbook_file '/var/www/html/info.php' do
  source 'info.php'
  mode 0644
end

template '/var/www/html/select.php' do
  source 'select.php.erb'
  mode 0777
  variables(
     idserver:node[:web][:idserver],
     pass: node[:web][:pass],
     ipdb: node[:web][:ipdb],
     usuario: node[:web][:usuario]
)
end


