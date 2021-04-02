# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.

# Setup keys for inter-VM communitcation to the :share VM
_, priv_key, pub_key = [nil, nil, nil]
unless File.exist? "test/share.id_rsa" and File.exist? "test/share.id_rsa.pub"
  require "vagrant/util/keypair"

  _, priv_key, pub_key = Vagrant::Util::Keypair.create

  File.write "test/share.id_rsa",     priv_key
  File.write "test/share.id_rsa.pub", pub_key
end

Vagrant.configure("2") do |config|
  config.vm.provider "virtualbox"

  # Appliance VM for doing tests on
  config.vm.define :appliance do |miq|
    miq.vm.box = "manageiq/master"
    # If you need help downloading this box, there is a helper script found here:
    #
    #   $ https://github.com/NickLaMuro/miq_tools/pull/13
    #
    # TODO:  Determine if it makes sense to just use these settings
    # miq.vm.box_version = "20190629"
    # miq.vm.box_url = "http://releases.manageiq.org/manageiq-vagrant-master-20190629-b20592c188.box"

    miq.vm.network :private_network, :ip => '192.168.50.10'

    miq.vm.synced_folder ".", "/vagrant", disabled: true

    rsync_opts = {
      :type           => :rsync,
      :rsync__exclude => [".git/", "tmp/"]
    }

    miq.vm.synced_folder "../manageiq-appliance_console", "/vagrant/manageiq-appliance_console", rsync_opts
    miq.vm.synced_folder "../manageiq-gems-pending",      "/vagrant/manageiq-gems-pending",      rsync_opts
    miq.vm.synced_folder "./test",                        "/vagrant/test",                       rsync_opts
    miq.vm.synced_folder "./provision_scripts",           "/vagrant/scripts",                    rsync_opts

    # Create a small disk we can add to the VM that we can stub in for `/tmp`
    #
    # Only make it 3MB in size (smaller than DB dump size after FS overhead)
    fake_tmp_fstab_entry = [
      "/dev/loop0".rjust(41),
      "/fake_tmp".rjust(37),
      "ext4".ljust(16),
      "loop".ljust(15),
      "0".ljust(8),
      "0"
    ].join " "
    miq.vm.provision "mount_fake_tmp", :type => "shell", :inline => <<-MOUNT_DISK
      dd if=/dev/zero of=/tmp/fake_tmp_fs bs=3M count=1
      losetup /dev/loop0 /tmp/fake_tmp_fs
      mkfs.ext4 /dev/loop0
      mkdir /fake_tmp
      echo "#{fake_tmp_fstab_entry}" >> /etc/fstab
      mount /dev/loop0
      chmod -R 777 /fake_tmp
      chmod +t /fake_tmp
    MOUNT_DISK

    ###### copy and update ssh key permissions
    miq.vm.provision "ssh_key", :type => "shell", :inline => <<-SSH_KEY
      cp /vagrant/test/share.id_rsa /home/vagrant/.ssh/
      chmod 0700 /home/vagrant/.ssh/share.id_rsa
      chown vagrant:vagrant /home/vagrant/.ssh/share.id_rsa
    SSH_KEY

    # Skip for now since we seem to need this for allowing seeding
    miq.vm.provision "stop_appliance", :type   => "shell", :run => "never",
                                       :inline => "systemctl stop evmserverd"

    # Now not needed since we us as hammer appliance, and sync kinda just
    # messes stuff up
    miq.vm.provision "sync",  :type => "shell", :run => "never",
                              :path => "provision_scripts/appliance_sync.sh"
    miq.vm.provision "reset", :type => "shell", :run => "never",
                              :path => "provision_scripts/appliance_reset.sh"

    # This is to allow `smartvm` to remain the password for `root`.  Required
    # after these changes to the appliance build:
    #
    #   https://github.com/ManageIQ/manageiq-appliance-build/pull/426
    #
    # Attempted with +chage+, but didn't work.  This just changes the password
    # once to 'vagrant', and then sets it back to 'smartvm' (default).
    miq.vm.provision "reset_root", :type => "shell", :inline => <<-RESET_ROOT
      echo -e "smartvm\\nvagrant\\nvagrant" | passwd --stdin root
      echo -e "smartvm\\nsmartvm"           | passwd --stdin root
    RESET_ROOT

    miq.vm.provision "seed", :type => "shell", :inline => <<-SEED
      SEED_SCRIPT_URL=https://gist.githubusercontent.com/NickLaMuro/87dddcfbd549b03099f8e55f632b2b57/raw/f0f2583bb453366304d61e41f7db18091d7e7d57/bz_1592480_db_replication_script.rb
      SEED_SCRIPT=/var/www/miq/vmdb/tmp/bz_1592480_db_replication_script.rb

      echo "check_file = File.join(File.dirname(__FILE__), 'db_seeding_done')" > $SEED_SCRIPT
      echo "exit if File.exist?(check_file)" >> $SEED_SCRIPT
      echo "" >> $SEED_SCRIPT
      echo "system 'sudo systemctl start evmserverd'" >> $SEED_SCRIPT
      echo "while User.count < 1" >> $SEED_SCRIPT
      echo "  sleep 5 # wait for seeing on the appliance to happen" >> $SEED_SCRIPT
      echo "end" >> $SEED_SCRIPT
      echo "" >> $SEED_SCRIPT
      curl --silent $SEED_SCRIPT_URL >> $SEED_SCRIPT
      echo "" >> $SEED_SCRIPT
      echo "" >> $SEED_SCRIPT
      echo "system 'sudo systemctl stop evmserverd'" >> $SEED_SCRIPT
      echo "system 'sudo systemctl disable evmserverd'" >> $SEED_SCRIPT
      echo "File.write(check_file, '')" >> $SEED_SCRIPT
      echo "" >> $SEED_SCRIPT

      cd /var/www/miq/vmdb
      source /etc/profile.d/evm.sh
      bin/rails r $SEED_SCRIPT
    SEED
  end

  # External vm for hosting nfs and samba mounts
  config.vm.define :share do |share|
    share.vm.box = "maier/alpine-3.6-x86_64"
    share.vm.guest = :tinycore  # hack to allow networking to be configured via vagrant
    share.vm.synced_folder ".", "/vagrant", disabled: true
    share.vm.network :private_network, :ip => '192.168.50.11'

    share.vm.provision "file", :source => "./test/share.id_rsa.pub", :destination => "$HOME/share.id_rsa.pub"

    # TODO:  Convert this monster to a shared set of ansible playbooks and roles.
    share.vm.provision "bootstrap", :type => "shell",
      :inline => <<-BOOTSTRAP.gsub(/ {8}/, '')
        cat share.id_rsa.pub >> .ssh/authorized_keys

        apk update
        apk add openssl-dev gcc memcached sqlite-libs xfsprogs git build-base  \
          libffi-dev libxml2-dev libxml2 libxslt-dev autoconf automake libtool \
          linux-headers rsync rsyslog python-dev py2-pip

        echo "http://dl-cdn.alpinelinux.org/alpine/v3.4/main" >> /etc/apk/repositories
        apk update
        apk add nfs-utils samba samba-common-tools "python3-dev<3.6" "python3<3.6" vsftpd

        echo "http://dl-cdn.alpinelinux.org/alpine/v3.8/main" >> /etc/apk/repositories
        apk update
        apk add "postgresql>9.6" "postgresql-client>9.6"

        # ==========   [Config/Run NFS]   ==========

        mkdir -p /var/nfs
        touch /var/nfs/foo
        touch /var/nfs/bar
        adduser -D nfsnobody
        chown nfsnobody:nfsnobody /var/nfs
        chmod 755 /var/nfs
        echo "/var/nfs    192.168.50.10(rw,sync,no_root_squash,no_subtree_check)" > /etc/exports
        rc-update add nfs
        rc-service nfs start


        # ==========   [Config/Run SMB]   ==========

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


        # ==========  [Config/Run PSQL]   ==========

        rc-update add postgresql
        rc-service postgresql start

        echo "listen_addresses = '*'" >> /var/lib/postgresql/10/data/postgresql.conf
        echo "host all all 192.168.50.10/0 md5" >> /var/lib/postgresql/10/data/pg_hba.conf
        psql -U postgres -c "CREATE ROLE root WITH LOGIN CREATEDB SUPERUSER PASSWORD 'smartvm'" postgres
        rc-service postgresql restart


        # ==========   [Config/Run FTP]   ==========

        cat << EOF > /etc/vsftpd/vsftpd.conf
        listen=NO
        listen_ipv6=YES

        local_enable=YES
        local_umask=022
        write_enable=YES
        connect_from_port_20=YES

        anonymous_enable=YES
        anon_root=/var/nfs/ftp/pub
        anon_umask=022
        anon_upload_enable=YES
        anon_mkdir_write_enable=YES
        anon_other_write_enable=YES

        pam_service_name=vsftpd
        userlist_enable=YES
        userlist_deny=NO
        seccomp_sandbox=NO
        EOF

        cat << EOF > /etc/vsftpd.user_list
        vagrant
        anonymous
        EOF

        mkdir -p /var/nfs/ftp/pub/uploads
        chown -R ftp:ftp /var/nfs/ftp
        chmod -R 555 /var/nfs/ftp/pub
        chmod 777 /var/nfs/ftp/pub/uploads

        rc-update add vsftpd
        rc-service vsftpd start
      BOOTSTRAP
  end
end
