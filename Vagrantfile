# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.

# Setup keys for inter-VM communitcation to the :share VM
_, priv_key, pub_key = [nil, nil, nil]
unless File.exist? "share.id_rsa" and File.exist? "share.id_rsa.pub"
  puts "NOT NEEDED"
  require "vagrant/util/keypair"

  _, priv_key, pub_key = Vagrant::Util::Keypair.create

  File.write "share.id_rsa",     priv_key
  File.write "share.id_rsa.pub", pub_key
end

Vagrant.configure("2") do |config|
  config.vm.provider "virtualbox"

  # Appliance VM for doing tests on
  config.vm.define :appliance do |miq|
    miq.vm.box = "manageiq/gaprindashvili"
    miq.vm.network :private_network, :ip => '192.168.50.10'

    miq.vm.synced_folder ".", "/vagrant", disabled: true

    rsync_opts = {
      :type           => :rsync,
      :rsync__exclude => [".git/", "tmp/"]
    }

    miq.vm.synced_folder "../awesome_spawn",              "/vagrant/awesome_spawn",              rsync_opts
    miq.vm.synced_folder "../manageiq/lib",               "/vagrant/manageiq/lib",               :type => :rsync
    miq.vm.synced_folder "../manageiq-gems-pending",      "/vagrant/manageiq-gems-pending",      rsync_opts
    miq.vm.synced_folder "../manageiq-performance",       "/vagrant/manageiq-performance",       rsync_opts
    miq.vm.synced_folder "../manageiq-appliance_console", "/vagrant/manageiq-appliance_console", rsync_opts
    miq.vm.synced_folder "./",                            "/vagrant/tests",                      rsync_opts

    miq.vm.provision "stop_appliance", :type => "shell", :run => "always", :inline => "systemctl stop evmserverd"

    miq.vm.provision "sync", :type => "shell", :run => "always", :inline => <<-SYNC
      APPLIANCE_AWESOME_SPAWN_DIR=$(ls -d /usr/local/lib/ruby/gems/2.3.0/gems/awesome_spawn-* | tail -n 1)
      APPLIANCE_GEMS_PENDING_DIR=$(ls -d /usr/local/lib/ruby/gems/2.3.0/bundler/gems/manageiq-gems-pending-* | tail -n 1)
      APPLIANCE_CONSOLE_DIR=$(ls -d /usr/local/lib/ruby/gems/2.3.0/gems/manageiq-appliance_console-* | tail -n 1)

      ###### awesome_spawn changes
      cp /vagrant/awesome_spawn/lib/awesome_spawn.rb \
         $APPLIANCE_AWESOME_SPAWN_DIR/lib/awesome_spawn.rb

      mkdir -p $APPLIANCE_AWESOME_SPAWN_DIR/lib/core_ext
      cp /vagrant/awesome_spawn/lib/core_ext/* \
         $APPLIANCE_AWESOME_SPAWN_DIR/lib/core_ext/

      ###### manageiq changes
      cp /vagrant/manageiq/lib/evm_database_ops.rb \
         /var/www/miq/vmdb/lib/evm_database_ops.rb
      cp /vagrant/manageiq/lib/tasks/evm_dba.rake \
         /var/www/miq/vmdb/lib/tasks/evm_dba.rake

      # ###### manageiq-gems-pending changes
      # cp /vagrant/manageiq-gems-pending/lib/gems/pending/util/postgres_admin.rb \
      #    $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/postgres_admin.rb
      # cp /vagrant/manageiq-gems-pending/lib/gems/pending/util/mount/miq_generic_mount_session.rb \
      #    $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/mount/miq_generic_mount_session.rb
      # cp /vagrant/manageiq-gems-pending/lib/gems/pending/util/mount/miq_glusterfs_session.rb \
      #    $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/mount/miq_glusterfs_session.rb
      # cp /vagrant/manageiq-gems-pending/lib/gems/pending/util/mount/miq_nfs_session.rb \
      #    $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/mount/miq_nfs_session.rb
      # cp /vagrant/manageiq-gems-pending/lib/gems/pending/util/mount/miq_smb_session.rb \
      #    $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/mount/miq_smb_session.rb
      # cp /vagrant/manageiq-gems-pending/lib/gems/pending/util/mount/miq_s3_session.rb \
      #    $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/mount/miq_s3_session.rb

      ###### manageiq-gems-pending "new" changes
      cp /vagrant/manageiq-gems-pending/lib/gems/pending/util/postgres_admin.rb \
         $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/postgres_admin.rb
      cp /vagrant/manageiq-gems-pending/lib/gems/pending/util/miq_file_storage.rb \
         $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/miq_file_storage.rb
      cp /vagrant/manageiq-gems-pending/lib/gems/pending/util/miq_object_storage.rb \
         $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/miq_object_storage.rb
      cp /vagrant/manageiq-gems-pending/lib/gems/pending/util/mount/miq_generic_mount_session.rb \
         $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/mount/miq_generic_mount_session.rb
      cp /vagrant/manageiq-gems-pending/lib/gems/pending/util/mount/miq_local_mount_session.rb \
         $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/mount/miq_local_mount_session.rb
      cp /vagrant/manageiq-gems-pending/lib/gems/pending/util/mount/miq_glusterfs_session.rb \
         $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/mount/miq_glusterfs_session.rb
      cp /vagrant/manageiq-gems-pending/lib/gems/pending/util/mount/miq_nfs_session.rb \
         $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/mount/miq_nfs_session.rb
      cp /vagrant/manageiq-gems-pending/lib/gems/pending/util/mount/miq_smb_session.rb \
         $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/mount/miq_smb_session.rb
      mkdir -p $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/object_storage
      cp /vagrant/manageiq-gems-pending/lib/gems/pending/util/object_storage/miq_s3_storage.rb \
         $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/object_storage/miq_s3_storage.rb

      # aws-sdk monkey patch
      mkdir -p $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/extensions/aws-sdk
      cp /vagrant/manageiq-gems-pending/lib/gems/pending/util/extensions/aws-sdk/s3_upload_stream_patch.rb \
         $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/extensions/aws-sdk/s3_upload_stream_patch.rb

      ###### manageiq-appliance_console changes
      cp /vagrant/manageiq-appliance_console/bin/appliance_console \
        $APPLIANCE_CONSOLE_DIR/bin/appliance_console
      cp /vagrant/manageiq-appliance_console/lib/manageiq-appliance_console.rb \
        $APPLIANCE_CONSOLE_DIR/lib/manageiq-appliance_console.rb
      cp /vagrant/manageiq-appliance_console/lib/manageiq/appliance_console/database_admin.rb \
        $APPLIANCE_CONSOLE_DIR/lib/manageiq/appliance_console/database_admin.rb
      cp /vagrant/manageiq-appliance_console/lib/manageiq/appliance_console/database_configuration.rb \
        $APPLIANCE_CONSOLE_DIR/lib/manageiq/appliance_console/database_configuration.rb
      cp /vagrant/manageiq-appliance_console/lib/manageiq/appliance_console/i18n.rb \
        $APPLIANCE_CONSOLE_DIR/lib/manageiq/appliance_console/i18n.rb
      cp /vagrant/manageiq-appliance_console/lib/manageiq/appliance_console/prompts.rb \
        $APPLIANCE_CONSOLE_DIR/lib/manageiq/appliance_console/prompts.rb
      cp /vagrant/manageiq-appliance_console/locales/appliance/en.yml \
        $APPLIANCE_CONSOLE_DIR/locales/appliance/en.yml

      ###### copy and update ssh key permissions
      cp /vagrant/tests/share.id_rsa /home/vagrant/.ssh/
      chmod 0700 /home/vagrant/.ssh/share.id_rsa
      chown vagrant:vagrant /home/vagrant/.ssh/share.id_rsa
    SYNC

    miq.vm.provision "seed", :type => "shell", :inline => <<-SEED
      SEED_SCRIPT_URL=https://gist.githubusercontent.com/NickLaMuro/87dddcfbd549b03099f8e55f632b2b57/raw/ce8790f1037dcd32ab38a7988cca61d62c7400b6/bz_1592480_db_replication_script.rb
      SEED_SCRIPT=/var/www/miq/vmdb/tmp/bz_1592480_db_replication_script.rb

      echo "check_file = File.join(File.dirname(__FILE__), 'db_seeding_done')" > $SEED_SCRIPT
      echo "exit if File.exist?(check_file)" >> $SEED_SCRIPT
      echo "" >> $SEED_SCRIPT
      curl --silent $SEED_SCRIPT_URL >> $SEED_SCRIPT
      echo "" >> $SEED_SCRIPT
      echo "File.write(check_file, '')" >> $SEED_SCRIPT
      echo "" >> $SEED_SCRIPT

      # Currently not working... don't want to fix now...
      #
      # For now log in to the appliance an run:
      #
      #     $ vmdb
      #     $ sudo /bin/sh -c "source /etc/profile.d/evm.sh; bin/rails r tmp/bz_1592480_db_replication_script.rb"
      #
      # cd /var/www/miq/vmdb
      # source /etc/profile.d/evm.sh
      # bin/rails r $SEED_SCRIPT
    SEED
  end

  # External vm for hosting nfs and samba mounts
  config.vm.define :share do |share|
    share.vm.box = "maier/alpine-3.6-x86_64"
    share.vm.guest = :tinycore
    share.vm.synced_folder ".", "/vagrant", disabled: true
    share.vm.network :private_network, :ip => '192.168.50.11'

    config.vm.provision "file", :source => "./share.id_rsa.pub", :destination => "$HOME/share.id_rsa.pub"

    share.vm.provision "bootstrap", :type => "shell", 
      :inline => <<-BOOTSTRAP.gsub(/ {8}/, '')
        cat share.id_rsa.pub >> .ssh/authorized_keys

        echo "http://dl-cdn.alpinelinux.org/alpine/v3.4/main" >> /etc/apk/repositories
        apk update
        apk add nfs-utils samba samba-common-tools \
          "postgresql<9.6" "postgresql-client<9.6"

        mkdir -p /var/nfs
        touch /var/nfs/foo
        touch /var/nfs/bar
        adduser -D nfsnobody
        chown nfsnobody:nfsnobody /var/nfs
        chmod 755 /var/nfs
        echo "/var/nfs    192.168.50.10(rw,sync,no_root_squash,no_subtree_check)" > /etc/exports
        rc-update add nfs
        rc-service nfs start


        mkdir -p /var/smb
        chmod 0777 /var/smb
        touch /var/smb/baz
        touch /var/smb/qux

        printf "vagrant\\nvagrant\\n" | smbpasswd -a -s vagrant
        cp /etc/samba/smb.conf /etc/samba/smb.conf.bak
        cat << EOF > /etc/samba/smb.conf
        [global]
           workgroup = WORKGROUP
           server string = Samba Server %v
           dos charset = cp850
           unix charset = ISO-8859-1
           force user = vagrant
           log file = /var/log/samba/log.%m
           max log size = 50
           security = user

        [share]
           path = /var/smb
           valid users = vagrant
           browseable = yes
           writeable = yes
        EOF
        rc-update add samba
        rc-service samba start

        rc-update add postgresql
        rc-service postgresql start

        echo "listen_addresses = '*'" >> /var/lib/postgresql/9.5/data/postgresql.conf
        echo "host all all 192.168.50.10/0 md5" >> /var/lib/postgresql/9.5/data/pg_hba.conf
        psql -U postgres -c "CREATE ROLE root WITH LOGIN CREATEDB SUPERUSER PASSWORD 'smartvm'" postgres
        rc-service postgresql restart
      BOOTSTRAP
  end
end
