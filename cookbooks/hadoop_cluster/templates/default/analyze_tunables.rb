#!/usr/bin/env ruby
require 'yaml'
require 'gorillib/model'
require 'gorillib/hash/mash'

class Gorillib::Field
  field :units,     :symbol
  field :hadoop_1,  :string
  field :min,       Whatever
  field :max,       Whatever
  field :recommend, Whatever
end

class Units
  extend self
  KB = KiB   = 2**10
  MB = MiB   = 2**20
  GB = GiB   = 2**30
  TB = TiB   = 2**40

  def quantified_bytes(val)
    case val.strip
    when /\A(\d+)[kK]\z/ then Integer($1) * KiB
    when /\A(\d+)[mM]\z/ then Integer($1) * MiB
    when /\A(\d+)[gG]\z/ then Integer($1) * GiB
    when /\A(\d+)[tT]\z/ then Integer($1) * TiB
    when /\A(\d+)\z/     then Integer($1)
    else val
    end
  end
end


class HadoopDaemon
  include Gorillib::Model
  field :dash_port,     :integer
  field :jmx_dash_port, :integer
  field :run_state,     :boolean
  field :java_heap_size_max, :string

  def receive_java_heap_size_max(val) super(Units.quantified_bytes(val)) ; end
end

class NamenodeDaemon
  field :ipc_port,     :integer
end
class SecondarynnDaemon
  field :ipc_port,     :integer
end
class JobtrackerDaemon
  field :ipc_port,     :integer
end
class DatanodeDaemon
  field :ipc_port,     :integer
  field :xcvr_port,     :integer
end
class TasktrackerDaemon
end

class HadoopConfig
  include Gorillib::Model

  class_attribute :daemons; self.daemons = [:namenode, :secondarynn, :jobtracker, :datanode, :tasktracker]

  def daemon_ram
    daemons.map{|dm| tunables[dm][:java_heap_size_max] }
  end

  def mapper_total_ram()
  end

end

tunables = Mash.new.merge!(YAML.load(File.read('/foo/hadoop-tunables.yaml')))
config = HadoopConfig.receive(tunables)

puts config
