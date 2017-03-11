bash 'open port' do
   code <<-EOH
   iptables -I INPUT 5 -p tcp -m state --state NEW -m tcp --dport 8080 -j ACCEPT
   iptables -I INPUT 5 -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
   service iptables save
   EOH
end

cookbook_file '/etc/yum.repos.d/nginx.repo' do
   source 'nginx.repo'
   mode 0777
end

package 'nginx'

template '/etc/nginx/nginx.conf' do
   source 'nginx.conf.erb'
   mode 0777
   variables(
      maqa: node[:balancer][:maqa],
      maqb: node[:balancer][:maqb]
   )
end

service 'nginx' do
   action [:enable, :start]
end
