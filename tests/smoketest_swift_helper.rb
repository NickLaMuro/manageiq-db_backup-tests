require 'etc'
require 'tmpdir'
require 'fog/openstack'

require_relative 'smoketest_constants'

class SwiftHelper
  SWIFT_SHARE_HOST              = "#{SHARE_IP}:8080".freeze
  SWIFT_SHARE_TENANT            = "test".freeze
  SWIFT_SHARE_USERNAME          = "tester".freeze
  SWIFT_SHARE_PASSWORD          = "testing".freeze
  SWIFT_SHARE_REGION            = "1".freeze
  SWIFT_SHARE_SECURITY_PROTOCOL = "non-ssl".freeze
  SWIFT_SHARE_API_VERSION       = "v3".freeze
  SWIFT_SHARE_DOMAIN_ID         = "default".freeze

  # Debugging helpers
  class << self
    attr_writer :container_prefix
  end

  def self.client
    @client ||= Fog::Storage::OpenStack.new(fog_params)
  end

  def self.suite_swift_container_name
    @suite_swift_container_name ||= Dir::Tmpname.make_tmpname container_prefix,
                                                              container_suffix
  end

  def self.create_container
    client.put_container suite_swift_container_name
  end

  def self.auth_creds
    [
      ENV["SWIFT_USERNAME"] || SWIFT_SHARE_USERNAME,
      ENV["SWIFT_PASSWORD"] || SWIFT_SHARE_PASSWORD
    ]
  end

  def self.file_exist? filename
    stat filename
  end

  def self.stat filename
    if filename.kind_of? Fog::Storage::OpenStack::File
      filename
    else
      get_file_list(filename).first
    end
  end

  def self.get_file_list prefix
    client.directories
          .get(suite_swift_container_name, :prefix => prefix)
          .files
    
  end

  def self.download_to dir, filename
    # Yes, this might seem stupid as why we are doing a File.join to then do a
    # `dirname` on that when we have the `dir` already.
    #
    # Well, the `filename` most likely will be namespaced with `db_dump` or
    # `db_backup`, so we want to make sure that is included in the `mkdir -p`.
    FileUtils.mkdir_p File.dirname(File.join(dir, filename))

    get_file_list(filename).each do |object|
      File.open File.join(dir, object.key), "wb" do |target_file|
        client.get_object(object.directory.key, object.key) do |chunk, _total, _left|
          target_file << chunk
        end
      end
    end
  end

  # Deletes all containers that have been created by this user from this lib
  #
  # By usinge client.delete_multiple_objects, we can delete the objects and the
  # container itself in a single request via the `bulk-delete` functionality.
  def self.clear_containers
    my_containers.each do |container|
      next if container.key == suite_swift_container_name # skip current container (just created)
      objects_to_delete  = container.files.map { |f| "#{container.key}/#{f.key}" }
      objects_to_delete << container.key
      client.delete_multiple_objects(nil, objects_to_delete)
    end
  end

  # Fetches all the containers made by this lib.
  #
  # Filters both by just the prefix (API filter) and then again in ruby just to
  # make sure what we are fetching by is as accurate as possible.
  def self.my_containers
    client.directories.all(:prefix => container_prefix)
          .select { |c| c.key.match(/^#{container_prefix}.*#{container_suffix}$/) }
  end

  def self.container_prefix
    @container_prefix ||= "#{Etc.getlogin}-"
  end

  def self.container_suffix
    @container_suffix ||= "appliance-console-smoketest".freeze
  end

  def self.suite_container_path_and_options
    return @suite_container_path_and_options if defined? @suite_container_path_and_options
    @suite_container_path_and_options = "/#{suite_swift_container_name}"
    params  = []
    params << "security_protocol=#{security_protocol}"    if security_protocol
    params << "api_version=#{api_version}"                if api_version
    params << "domain_id=#{domain_id}"                    if include_domain_id?
    params << "region=#{region}"                          if region
    @suite_container_path_and_options << "?#{params.join('&')}" unless params.empty?
    @suite_container_path_and_options
  end

  def self.fog_params
    {
      :openstack_auth_url          => auth_url,
      :openstack_username          => auth_creds.first,
      :openstack_api_key           => auth_creds.last,
      :openstack_project_domain_id => domain_id,
      :openstack_user_domain_id    => domain_id,
      :openstack_region            => region,
      :connection_options          => { :debug_request  => true }
    }
  end

  def self.auth_url
    auth_url = URI::Generic.build(
      :scheme => security_protocol == 'non-ssl' ? "http" : "https",
      :host   => host,
      :port   => port.to_i,
      :path   => "/#{api_version}/auth/tokens"
    ).to_s
  end

  def self.suite_host_name_and_port
    return @suite_host_name_and_port if defined? @suite_host_name_and_port
    @suite_host_name_and_port = ENV["SWIFT_HOST"] ||
                                SWIFT_SHARE_HOST
    @host, @port              = @suite_host_name_and_port.split(":")
    @suite_host_name_and_port
  end

  def self.host
    @host ||= begin
                suite_host_name_and_port
                @host
              end
  end

  def self.port
    @port ||= begin
                suite_host_name_and_port
                @port
              end
  end

  def self.security_protocol
    @security_protocol ||= if ENV["SWIFT_SECURITY_PROTOCOL"]
                             nil_if_empty ENV["SWIFT_SECURITY_PROTOCOL"]
                           else
                             SWIFT_SHARE_SECURITY_PROTOCOL
                           end
  end

  def self.api_version
    @api_version       ||= if ENV["SWIFT_API_VERSION"]
                             nil_if_empty ENV["SWIFT_API_VERSION"]
                           else
                             SWIFT_SHARE_API_VERSION
                           end
  end

  def self.domain_id
    @domain_id         ||= if ENV["SWIFT_DOMAIN_ID"]
                             nil_if_empty ENV["SWIFT_DOMAIN_ID"]
                           else
                             SWIFT_SHARE_DOMAIN_ID
                           end
  end

  def self.region
    @region            ||= if ENV["SWIFT_REGION"]
                             nil_if_empty ENV["SWIFT_REGION"]
                           else
                             SWIFT_SHARE_REGION
                           end
  end

  def self.tenant
    @tenant            ||= if ENV["SWIFT_TENANT"]
                             nil_if_empty ENV["SWIFT_TENANT"]
                           else
                             SWIFT_SHARE_TENANT
                           end
  end

  def self.nil_if_empty var
    var.strip.empty? ? nil : var
  end

  def self.include_domain_id?
    domain_id && api_version && api_version == "v3"
  end
end

# Create a container on load
if defined? TestConfig and TestConfig.include_swift
  SwiftHelper.create_container
end

# Make Fog::Storage::OpenStack::File sortable by key

# this next line just allows you to run this file and being able to comment out
# the SwiftHelper.create_container line in case you just need to test some
# things without automatically creating a container.
Fog::Storage::OpenStack.setup_requirements

Fog::Storage::OpenStack::File.prepend Module.new {
  def <=> other
    self.key <=> other.key
  end

  def size; content_length; end
}
