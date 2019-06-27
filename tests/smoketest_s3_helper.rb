require 'etc'
require 'tmpdir'
require 'aws-sdk'

class S3Helper
  def self.client
    @client ||= Aws::S3::Client.new
  end

  def self.suite_s3_bucket_name
    @suite_s3_bucket_name ||= Dir::Tmpname.make_tmpname bucket_prefix, bucket_suffix
  end

  def self.helper_bucket_tag_set
    [
      { 
        :key => "appliance_console_smoketest",
        :value => "true"
      }
    ]
  end

  def self.create_bucket
    client.create_bucket      :bucket  => suite_s3_bucket_name
    client.put_bucket_tagging :bucket  => suite_s3_bucket_name,
                              :tagging => { :tag_set => helper_bucket_tag_set }
  end

  def self.auth_creds
    [ENV["AWS_ACCESS_KEY_ID"], ENV["AWS_SECRET_ACCESS_KEY"]]
  end

  def self.rake_opts filename, options={}
    opts  = ["--uri", "s3://#{suite_s3_bucket_name}"]
    opts << "--uri-username"
    opts << (options[:redacted] ? "********" : ENV["AWS_ACCESS_KEY_ID"])
    opts << "--uri-password"
    opts << (options[:redacted] ? "********" : ENV["AWS_SECRET_ACCESS_KEY"])
    opts << "--remote-file-name"
    opts << filename
    opts.join(" ")
  end

  def self.to_uri filename
    "s3://#{suite_s3_bucket_name}/#{filename}"
  end

  def self.file_exist? filename
    stat filename
  end

  def self.stat filename
    if filename.kind_of? Aws::S3::Types::Object
      filename
    else
      get_file_list(filename).first
    end
  end

  def self.get_file_list prefix
    client.list_objects(:bucket => suite_s3_bucket_name, :prefix => prefix)
          .contents
  end

  def self.download_to dir, filename
    FileUtils.mkdir_p File.dirname(File.join(dir, filename))  # just incase
    client.list_objects(:bucket => suite_s3_bucket_name, :prefix => filename)
          .contents.map(&:key)
          .each do |object_key|
            client.get_object :bucket          => suite_s3_bucket_name,
                              :key             => object_key,
                              :response_target => File.join(dir, object_key)
          end
  end

  # Deletes all buckets that have been created by this user from this lib
  # (matches the generated name and tagging structure).
  #
  # First has to remove all objects that are within the bucket, if any, and
  # then removes the bucket itself.
  def self.clear_buckets
    my_buckets.each do |bucket|
      next if bucket == suite_s3_bucket_name # skip current bucket (just created)
      # puts bucket
      next unless is_smoketest_tagged?(bucket)
      # puts "  #{client.get_bucket_tagging(:bucket => bucket).to_h[:tag_set]}"
      bucket_objects = client.list_objects(:bucket => bucket).contents
      unless bucket_objects.empty?
        objects_to_delete = { :bucket  => bucket, :delete => { :objects => [] } }

        bucket_objects.inject(objects_to_delete) do |memo, obj|
          memo[:delete][:objects] << { :key => obj.key }
          memo
        end

        # puts "  #{objects_to_delete.inspect}"
        client.delete_objects(objects_to_delete)
      end
      client.delete_bucket(:bucket => bucket)
    end
  end

  def self.my_buckets
    client.list_buckets.buckets.map(&:name)
          .select { |n| n.match(/^#{bucket_prefix}.*#{bucket_suffix}$/) }
  end

  def self.is_smoketest_tagged? bucket
    client.get_bucket_tagging(:bucket => bucket).to_h[:tag_set] == helper_bucket_tag_set
  rescue Aws::S3::Errors::NoSuchTagSet
    false
  end

  def self.bucket_prefix
    @bucket_prefix ||= "#{Etc.getlogin}-"
  end

  def self.bucket_suffix
    @bucket_suffix ||= "appliance-console-smoketest"
  end
end

# Create a bucket on load
if defined? TestConfig and TestConfig.include_s3
  S3Helper.create_bucket
end

# Make Aws::S3::Type::Objects sortable by key
Aws::S3::Types::Object.prepend Module.new {
  def <=> other
    self.key <=> other.key
  end
}
