# Primer parcial Distribuidos
## Rodrigo Rivera


### Paso a paso:


#Aprovisionamiento de máquinas virtuales
Para lograr hacer el aprovisionamiento se debe crear un vagrant file junto con unos cookbooks que representan cada servicio que hace parte de la arquitectura (balanceador de cargas, web, base de datos).
Lo primero que debemos hacer es el vagrant file para aprovisionar cada una de las máquinas como podemos ver a continuación.
##Vagrant file

```ruby

# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.ssh.insert_key = false

  config.vm.define :centos_balancer do |balancer|
    balancer.vm.box = "centos64"
    balancer.vm.network :private_network, ip: "192.168.133.13"
    balancer.vm.network "public_network", bridge:  "eno1", ip:"192.168.131.85"
    balancer.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "1024","--cpus", "1", "--name", "centos_balancer"]
    end
    config.vm.provision :chef_solo do |chef|
      chef.cookbooks_path = "cookbooks"
      chef.add_recipe "balancer"
    end
  end

 

  config.vm.define :centos_web1 do |web|
    web.vm.box = "Centos64Updated"
    web.vm.network :private_network, ip: "192.168.133.10"
    web.vm.network "public_network", bridge:  "eno1", ip:"192.168.131.82"
    web.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "1024","--cpus", "1", "--name", "centos-web1" ]
    end
    config.vm.provision :chef_solo do |chef|
      chef.cookbooks_path = "cookbooks"
      chef.add_recipe "web"
      chef.json ={"web" => {"idserver" => "1"}} 
    end
  end

  config.vm.define :centos_web2 do |web|
    web.vm.box = "Centos64Updated"
    web.vm.network :private_network, ip: "192.168.133.11"
    web.vm.network "public_network", bridge:  "eno1", ip:"192.168.131.83"
    web.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "1024","--cpus", "1", "--name", "centos-web2" ]
    end
    config.vm.provision :chef_solo do |chef|
      chef.cookbooks_path = "cookbooks"
      chef.add_recipe "web"
      chef.json ={"web" => {"idserver" => "2"}} 
    end
  end

  config.vm.define :centos_db do |db|
    db.vm.box = "Centos64Updated"
    db.vm.network :private_network, ip: "192.168.133.12"
    db.vm.network "public_network", bridge:  "eno1", ip:"192.168.131.84"
    db.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "1024","--cpus", "1", "--name", "centos-db" ]
    end
    config.vm.provision :chef_solo do |chef|
      chef.cookbooks_path = "cookbooks"
      chef.add_recipe "db"
    end
  end
 

end
```

Podemos apreciar como se define el nombre de la base de datos en cada caso (para base de datos db= centos_db) en la cual se crea una máquina con el box Centos64Updated y se especifica la dirección ip de la máquina junto con la dirección e interfaz con la cual se hará puente para poder tener salida a la red del laboratorio (pool de direcciones asignada en clase) y se costumiza con cada parámetro (recursos de la máquina) necesario. Luego se especifica en cada segmento la herramienta de aprovisionamiento que se usará, en este caso, chef, además de la ruta en la cual se encuentra el cookbook respectivo para dicha máquina junto con las carpetas básicas (attributes, files, recipes, templates) y receta para que se implente el servicio deseado.

##Cookbooks
![Cookbooks parcial](images/cookbooks.png)
Aqui podemos apreciar los cookbooks necesarios para el aprovisionamiento de las máquinas con base en la arquitectura propuesta.
###Balancer
![Balancer-tree](images/tree-balancer.png)
####default.rb
```
default[:balancer][:maqa]='192.168.131.82'
default[:balancer][:maqb]='192.168.131.83'
```
####nginx.repo
```
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=0
enabled=1
```
####installbalancer.rb
```ruby
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
```
####nginx.conf.erb
```ruby
worker_processes  1;
events {
   worker_connections 1024;
}
http {
    upstream servers {
         server <%=@maqa%>;
         server <%=@maqb%>;
    }
    server {
        listen 8080;
        location / {
              proxy_pass http://servers;
        }
    }
}
```
![Web-tree](images/web-tree.png)
![Db-tree](images/db-tree.png)

