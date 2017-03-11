package 'mysql-server'
package 'expect'
service 'mysqld' do
  action [:enable, :start]
end

bash 'open port' do
  code <<-EOH
  iptables -I INPUT 5 -p tcp -m state --state NEW -m tcp --dport 3306 -j ACCEPT
  service iptables save
  EOH
end

template '/tmp/configure_mysql.sh' do
  source 'configure_mysql.sh.erb'
  mode 0777
  variables(
	password: node[:db][:password]
)
end
template '/tmp/create_schema.sql' do
  source 'create_schema.sql.erb'
  mode 0777
  variables(
	ipserv1: node[:db][:ipserv1],
	ipserv2: node[:db][:ipserv2],
	user: node[:db][:user],
	id: node[:db][:id]
)
end

bash 'configure mysql' do
  cwd '/tmp'
  code <<-EOH
  ./configure_mysql.sh
  EOH
end

bash 'create schema' do
	user 'root'
	cwd '/tmp'
	code <<-EOH
	cat create_schema.sql | mysql -u root -pdistribuidos
	EOH
end


