require 'active_support/core_ext/class/attribute_accessors'
require 'drb'
require 'json'
require 'path_manager'
require 'port'
require 'slice_exceptions'
require 'slice_extensions'

# Virtual slice.
# rubocop:disable ClassLength
class Slice
  extend DRb::DRbUndumped
  include DRb::DRbUndumped

  cattr_accessor(:all, instance_reader: false) { [] }

  def self.create(name)
    if find_by(name: name)
      fail SliceAlreadyExistsError, "Slice #{name} already exists"
    end
    new(name).tap { |slice| all << slice }
  end

  # This method smells of :reek:NestedIterators but ignores them
  def self.find_by(queries)
    queries.inject(all) do |memo, (attr, value)|
      memo.find_all { |slice| slice.__send__(attr) == value }
    end.first
  end

  def self.find_by!(queries)
    find_by(queries) || fail(SliceNotFoundError,
                             "Slice #{queries.fetch(:name)} not found")
  end

  def self.find(&block)
    all.find(&block)
  end

  def self.destroy(name)
    find_by!(name: name)
    Path.find { |each| each.slice == name }.each(&:destroy)
    all.delete_if { |each| each.name == name }
  end

  def self.destroy_all
    all.clear
  end

  attr_reader :name

  def initialize(name)
    @name = name
    @ports = Hash.new([].freeze)
  end
  private_class_method :new

  def add_port(port_attrs)
    port = Port.new(port_attrs)
    if @ports.key?(port)
      fail PortAlreadyExistsError, "Port #{port.name} already exists"
    end
    @ports[port] = [].freeze
  end

  def delete_port(port_attrs)
    find_port port_attrs
    Path.find { |each| each.slice == @name }.select do |each|
      each.port?(Topology::Port.create(port_attrs))
    end.each(&:destroy)
    @ports.delete Port.new(port_attrs)
  end

  def find_port(port_attrs)
    mac_addresses port_attrs
    Port.new(port_attrs)
  end

  def each(&block)
    @ports.keys.each do |each|
      block.call each, @ports[each]
    end
  end

  def ports
    @ports.keys
  end

  def add_mac_address(mac_address, port_attrs)
    port = Port.new(port_attrs)
    if @ports[port].include? Pio::Mac.new(mac_address)
      fail(MacAddressAlreadyExistsError,
           "MAC address #{mac_address} already exists")
    end
    @ports[port] += [Pio::Mac.new(mac_address)]
  end

  def delete_mac_address(mac_address, port_attrs)
    find_mac_address port_attrs, mac_address
    @ports[Port.new(port_attrs)] -= [Pio::Mac.new(mac_address)]

    Path.find { |each| each.slice == @name }.select do |each|
      each.endpoints.include? [Pio::Mac.new(mac_address),
                               Topology::Port.create(port_attrs)]
    end.each(&:destroy)
  end

  def find_mac_address(port_attrs, mac_address)
    find_port port_attrs
    mac = Pio::Mac.new(mac_address)
    if @ports[Port.new(port_attrs)].include? mac
      mac
    else
      fail MacAddressNotFoundError, "MAC address #{mac_address} not found"
    end
  end

  def mac_addresses(port_attrs)
    port = Port.new(port_attrs)
    @ports.fetch(port)
  rescue KeyError
    raise PortNotFoundError, "Port #{port.name} not found"
  end

  def member?(host_id)
    @ports[Port.new(host_id)].include? host_id[:mac]
  rescue
    false
  end

  def to_s
    @name
  end

  def to_json(*_)
    %({"name": "#{@name}"})
  end

  def method_missing(method, *args, &block)
    @ports.__send__ method, *args, &block
  end


  def self.split_slice(orig, into1, into2)
    into1_name = into1.split("^")	#[0]:name, [1,2,...]:hosts
    into1_hosts = into1_name[1].split(",")
    into2_name = into2.split("^")
    into2_hosts = into2_name[1].split(",")
    orig_slice = find_by!(name: orig)
    #into1_host, into2_hostがorig_sliceのすべてのhostを含んでいるか、足りていなかったらエラー
    into_all_hosts = into1_hosts + into2_hosts
puts "AllHosts: #{into_all_hosts}"
    orig_all_hosts = []
    orig_slice.each do |port, mac_addresses|
      mac_addresses.each{|mac_address| orig_all_hosts << mac_address.to_s}
    end
puts "AllOrigHosts: #{orig_all_hosts}"
    fail SplitArgumentError, "Split Argument is mistaken" if into_all_hosts.sort != orig_all_hosts.sort
    #create new slices
    create(into1_name[0])
    slice1 = find_by!(name: into1_name[0])
    create(into2_name[0])
    slice2 = find_by!(name: into2_name[0])
    #add hosts to each slices
    orig_slice.each do |port, mac_addresses|
      mac_addresses.each do |mac_address|
        slice1.add_mac_address(mac_address, port) if into1_hosts.include?(mac_address)
        slice2.add_mac_address(mac_address, port) if into2_hosts.include?(mac_address)
      end
    end
    destroy(orig)
    puts "split #{orig} into #{into1} and #{into2}"  
  end


  def self.merge_slices(orig, merg)
    orig_slice = find_by!(name: orig)
    merg_slice = find_by!(name: merg)
    merg_slice.each do |port, mac_addresses|
      mac_addresses.each{|each| orig_slice.add_mac_address(each, port)}
    end
    destroy(merg)
    puts "merge #{orig} with #{merg}"
  end
end
# rubocop:enable ClassLength
