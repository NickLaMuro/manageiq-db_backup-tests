# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
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
      cp /vagrant/manageiq/lib/manageiq/util/file_splitter.rb \
         /var/www/miq/vmdb/lib/manageiq/util/file_splitter.rb
      cp /vagrant/manageiq/lib/manageiq/util/ftp_lib.rb \
         /var/www/miq/vmdb/lib/manageiq/util/ftp_lib.rb
      cp /vagrant/manageiq/lib/tasks/evm_dba.rake \
         /var/www/miq/vmdb/lib/tasks/evm_dba.rake

      ###### manageiq-gems-pending changes
      cp /vagrant/manageiq-gems-pending/lib/gems/pending/util/postgres_admin.rb \
         $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/postgres_admin.rb

      ###### manageiq-appliance_console changes
      # cp /vagrant/manageiq-appliance_console/lib/
      #   $APPLIANCE_CONSOLE_DIR/lib/
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

    share.vm.provision "bootstrap", :type => "shell", 
      :inline => <<-BOOTSTRAP.gsub(/ {8}/, '')
        apk update
        apk add nfs-utils samba samba-common-tools

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
      BOOTSTRAP
  end
end
