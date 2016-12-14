require 'grape'
require 'port'
require 'slice_exceptions'
require 'slice_extensions'
require 'trema'

module DRb
  # delegates to_json to remote object
  class DRbObject
    def to_json(*args)
      method_missing :to_json, *args
    end
  end
end

# Remote Slice class proxy
class Slice
  def self.method_missing(method, *args, &block)
    socket_dir = if FileTest.exists?('RoutingSwitch.ctl')
                   '.'
                 else
                   ENV['TREMA_SOCKET_DIR'] || Trema::DEFAULT_SOCKET_DIR
                 end
    remote_klass =
      Trema.trema_process('RoutingSwitch', socket_dir).controller.slice
    remote_klass.__send__(method, *args, &block)
  end
end

# REST API of Slice
# rubocop:disable ClassLength
class RestApi < Grape::API
  format :json

  helpers do
    def rest_api
      yield
    rescue Slice::NotFoundError => not_found_error
      error! not_found_error.message, 404
    rescue Slice::AlreadyExistsError => already_exists_error
      error! already_exists_error.message, 409
    end
  end

  desc 'Creates a slice.'
  params do
    requires :name, type: String, desc: 'Slice ID.'
  end
  post :slices do
    rest_api { Slice.create params[:name] }
  end

  desc 'Deletes a slice.'
  params do
    requires :name, type: String, desc: 'Slice ID.'
  end
  delete :slices do
    rest_api { Slice.destroy params[:name] }
  end

  desc 'Lists slices.'
  get :slices do
    rest_api { Slice.all }
  end

  desc 'Shows a slice.'
  params do
    requires :slice_id, type: String, desc: 'Slice ID.'
  end
  get 'slices/:slice_id' do
    rest_api { Slice.find_by!(name: params[:slice_id]) }
  end

  desc 'Adds a port to a slice.'
  params do
    requires :slice_id, type: String, desc: 'Slice ID.'
    requires :dpid, type: Integer, desc: 'Datapath ID.'
    requires :port_no, type: Integer, desc: 'Port number.'
  end
  post 'slices/:slice_id/ports' do
    rest_api do
      Slice.find_by!(name: params[:slice_id]).
        add_port(dpid: params[:dpid], port_no: params[:port_no])
    end
  end

  desc 'Deletes a port from a slice.'
  params do
    requires :slice_id, type: String, desc: 'Slice ID.'
    requires :dpid, type: Integer, desc: 'Datapath ID.'
    requires :port_no, type: Integer, desc: 'Port number.'
  end
  delete 'slices/:slice_id/ports' do
    rest_api do
      Slice.find_by!(name: params[:slice_id]).
        delete_port(dpid: params[:dpid], port_no: params[:port_no])
    end
  end

  desc 'Lists ports.'
  params do
    requires :slice_id, type: String, desc: 'Slice ID.'
  end
  get 'slices/:slice_id/ports' do
    rest_api { Slice.find_by!(name: params[:slice_id]).ports }
  end

  desc 'Shows a port.'
  params do
    requires :slice_id, type: String, desc: 'Slice ID.'
    requires :port_id, type: String, desc: 'Port ID.'
  end
  get 'slices/:slice_id/ports/:port_id' do
    rest_api do
      Slice.find_by!(name: params[:slice_id]).
        find_port(Port.parse(params[:port_id]))
    end
  end

  desc 'Adds a host to a slice.'
  params do
    requires :slice_id, type: String, desc: 'Slice ID.'
    requires :port_id, type: String, desc: 'Port ID.'
    requires :name, type: String, desc: 'MAC address.'
  end
  post '/slices/:slice_id/ports/:port_id/mac_addresses' do
    rest_api do
      Slice.find_by!(name: params[:slice_id]).
        add_mac_address(params[:name], Port.parse(params[:port_id]))
    end
  end

  desc 'Deletes a host from a slice.'
  params do
    requires :slice_id, type: String, desc: 'Slice ID.'
    requires :port_id, type: String, desc: 'Port ID.'
    requires :name, type: String, desc: 'MAC address.'
  end
  delete '/slices/:slice_id/ports/:port_id/mac_addresses' do
    rest_api do
      Slice.find_by!(name: params[:slice_id]).
        delete_mac_address(params[:name], Port.parse(params[:port_id]))
    end
  end

  desc 'List MAC addresses.'
  params do
    requires :slice_id, type: String, desc: 'Slice ID.'
    requires :port_id, type: String, desc: 'Port ID.'
  end
  get 'slices/:slice_id/ports/:port_id/mac_addresses' do
    rest_api do
      Slice.find_by!(name: params[:slice_id]).
        mac_addresses(Port.parse(params[:port_id]))
    end
  end

  desc 'Shows a MAC address.'
  params do
    requires :slice_id, type: String, desc: 'Slice ID.'
    requires :port_id, type: String, desc: 'Port ID.'
    requires :mac_address_id, type: String, desc: 'MAC address.'
  end
  get 'slices/:slice_id/ports/:port_id/mac_addresses/:mac_address_id' do
    rest_api do
      Slice.find_by!(name: params[:slice_id]).
        find_mac_address(Port.parse(params[:port_id]), params[:mac_address_id])
    end
  end

  desc 'Merge a slice with a slice'
  params do
    requires :orig_slice_id, type: String, desc: 'Slice ID.'
    requires :merg_slice_id, type: String, desc: 'Slice ID.'
  end
  post 'slices/:orig_slice_id/:merg_slice_id' do
    rest_api do
      Slice.merge_slices(params[:orig_slice_id], params[:merg_slice_id])
    end
  end

  desc 'Split a slice into two slices'
  params do
    requires :orig_slice_id, type: String, desc: 'Slice ID.'
    requires :split_slice_id1, type: String, desc: 'Split Slice ID1'
    requires :split_slice_id2, type: String, desc: 'Split Slice ID2'
    requires :split_hosts1, type: String, desc: 'Split hosts1'
    requires :split_hosts2, type: String, desc: 'Split hosts2'
  end
  post 'slices/:orig_slice_id/:split_slice_id1/split_hosts1/:split_slice_id2/:split_hosts2' do
    rest_api do
      split_arg1 = params[:split_slice_id1] + '^' + params[:split_hosts1]
      split_arg2 = params[:split_slice_id2] + '^' + params[:split_hosts2]
      Slice.split_slice(params[:orig_slice_id], split_arg1, split_arg2)
    end
  end



end
# rubocop:enable ClassLength
