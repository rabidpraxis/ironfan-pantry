module HadoopCluster
  # installs given hadoop package using the configured deb version
  def hadoop_package component
    package_name = (component ? "#{node[:hadoop][:handle]}-#{component}" : "#{node[:hadoop][:handle]}")
    package package_name do
      if node[:hadoop][:deb_version] != 'current'
        version node[:hadoop][:deb_version]
      end
    end
  end

  # the hadoop services this machine provides
  def hadoop_services
    %w[namenode secondarynn jobtracker datanode tasktracker].select do |svc|
      node[:announces]["#{node[:cluster_name]}-hadoop-#{svc}"]
    end
  end

  # hash of hadoop options suitable for passing to template files
  def hadoop_config_hash
    hsh = Mash.new()
    hsh.merge!({
        :aws              => (node[:aws] && node[:aws].to_hash),
        :extra_classpaths => node[:hadoop][:extra_classpaths].map{|nm, classpath| classpath }.flatten,
      })
    java_opts              = node[:hadoop][:java_child_opts]
    if node[:hadoop][:task_profile]
      java_opts += " -Xprof -verbose:gc -Xloggc:/tmp/hdp-task-gc-@taskid@.log"
      # java_opts += "-Dcom.sun.management.jmxremote -Djava.rmi.server.hostname=#{node[:hadoop][:jmx_dash_addr]} -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false"
      # -agentlib:hprof=cpu=samples,interval=1,file=<outputfilename>
    end
    hsh[:java_map_opts]    = "#{java_opts} -Xmx#{node[:hadoop][:map_heap_mb]}m"
    hsh[:java_reduce_opts] = "#{java_opts} -Xmx#{node[:hadoop][:reduce_heap_mb]}m"

    hsh.merge(node[:hadoop])
  end

  # Create a symlink to a directory, wiping away any existing dir that's in the way
  def force_link dest, src
    directory(dest) do
      action :delete ; recursive true
      not_if{ File.symlink?(dest) }
    end
    link(dest){ to src }
  end

end

class Chef::Recipe              ; include HadoopCluster ; end
class Chef::Resource::Directory ; include HadoopCluster ; end
class Chef::Resource::Execute   ; include HadoopCluster ; end
class Chef::Resource::Template  ; include HadoopCluster ; end
class Erubis::Context           ; include HadoopCluster ; end
