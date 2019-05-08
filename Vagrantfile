# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.

# Setup keys for inter-VM communitcation to the :share VM
_, priv_key, pub_key = [nil, nil, nil]
unless File.exist? "share.id_rsa" and File.exist? "share.id_rsa.pub"
  require "vagrant/util/keypair"

  _, priv_key, pub_key = Vagrant::Util::Keypair.create

  File.write "share.id_rsa",     priv_key
  File.write "share.id_rsa.pub", pub_key
end

Vagrant.configure("2") do |config|
  config.vm.provider "virtualbox"

  # Appliance VM for doing tests on
  config.vm.define :appliance do |miq|
    miq.vm.box = "manageiq/hammer"
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

    # Now not needed since we us as hammer appliance, and sync kinda just
    # messes stuff up
    miq.vm.provision "sync",  :type => "shell", :run => "never",
                              :path => "vagrant_provision_appliance_sync.sh"
    miq.vm.provision "reset", :type => "shell", :run => "never",
                              :path => "vagrant_provision_appliance_reset.sh"

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

    share.vm.provision "file", :source => "./share.id_rsa.pub", :destination => "$HOME/share.id_rsa.pub"

    share.vm.provision "bootstrap", :type => "shell", 
      :inline => <<-BOOTSTRAP.gsub(/ {8}/, '')
        cat share.id_rsa.pub >> .ssh/authorized_keys

        apk update
        apk add openssl-dev gcc memcached sqlite-libs xfsprogs git build-base  \
          libffi-dev libxml2-dev libxml2 libxslt-dev autoconf automake libtool \
          linux-headers rsync rsyslog python-dev py2-pip

        echo "http://dl-cdn.alpinelinux.org/alpine/v3.4/main" >> /etc/apk/repositories
        apk update
        apk add nfs-utils samba samba-common-tools \
          "postgresql<9.6" "postgresql-client<9.6" "python3-dev<3.6" "python3<3.6" vsftpd

        # ==========  [Setup Swift User]  ==========
        adduser -D swift


        # ==========  [Setup Swift Dirs]  ==========
        cat << EOF | xargs -I {} /bin/sh -c "mkdir -p {} && chown swift:swift {}"
        /opt/swift
        /var/run/swift
        /etc/swift
        /etc/swift/account-server
        /etc/swift/container-server
        /etc/swift/object-server
        EOF

        # ========== [Clone Swift Source] ==========
        git clone --depth 1 -b 2.19.0 git://github.com/openstack/swift.git /opt/swift/swift
        git clone --depth 1 -b 1.5.0 git://github.com/openstack/liberasurecode.git /opt/swift/liberasurecode
        git clone --depth 1 -b 1.5.0 git://github.com/openstack/pyeclib.git /opt/swift/pyeclib
        git clone --depth 1 -b 14.0.0 git://github.com/openstack/keystone.git /opt/keystone


        # ==========   [Install Source]   ==========

        su -c 'cd /opt/swift/liberasurecode && ./autogen.sh && ./configure && make && make install && ldconfig'
        su -c 'cd /opt/swift/pyeclib && pip install -e .'
        su -c 'cd /opt/swift/swift && pip install -e .[kmip_keymaster]'


        # ==========  [Setup Swift Data]  ==========
        mkdir -p /srv /mnt/sdb1
        truncate -s 250M /srv/swift-disk
        (blkid | grep /srv/swift-disk | grep -q 'TYPE="xfs"') || mkfs.xfs /srv/swift-disk
        grep swift-disk /etc/fstab || echo '/srv/swift-disk /mnt/sdb1 xfs loop,noatime,nodiratime,nobarrier,logbufs=8 0 0' >> /etc/fstab
        mountpoint -q /mnt/sdb1 || mount /mnt/sdb1

        for x in 1 2 3 4; do
          mkdir -p /mnt/sdb1/$x
          ln -s /mnt/sdb1/$x /srv/$x
          mkdir -p /srv/$x/node/sdb$x /srv/$x/node/sdb$((x + 4))
          chown swift:swift /mnt/sdb1/*
          chown swift:swift -R /srv/$x/
        done


        # ========== [rsyncd Swift Conf]  ==========

        cat << EOF > /etc/rsyncd.conf
        uid = swift
        gid = swift
        log file = /var/log/rsyncd.log
        pid file = /var/run/rsyncd.pid
        address = 0.0.0.0


        [account6012]
        max connections = 25
        path = /srv/1/node/
        read only = false
        lock file = /var/lock/account6012.lock

        [account6022]
        max connections = 25
        path = /srv/2/node/
        read only = false
        lock file = /var/lock/account6022.lock

        [account6032]
        max connections = 25
        path = /srv/3/node/
        read only = false
        lock file = /var/lock/account6032.lock

        [account6042]
        max connections = 25
        path = /srv/4/node/
        read only = false
        lock file = /var/lock/account6042.lock

        [container6011]
        max connections = 25
        path = /srv/1/node/
        read only = false
        lock file = /var/lock/container6011.lock

        [container6021]
        max connections = 25
        path = /srv/2/node/
        read only = false
        lock file = /var/lock/container6021.lock

        [container6031]
        max connections = 25
        path = /srv/3/node/
        read only = false
        lock file = /var/lock/container6031.lock

        [container6041]
        max connections = 25
        path = /srv/4/node/
        read only = false
        lock file = /var/lock/container6041.lock

        [object6010]
        max connections = 25
        path = /srv/1/node/
        read only = false
        lock file = /var/lock/object6010.lock

        [object6020]
        max connections = 25
        path = /srv/2/node/
        read only = false
        lock file = /var/lock/object6020.lock

        [object6030]
        max connections = 25
        path = /srv/3/node/
        read only = false
        lock file = /var/lock/object6030.lock

        [object6040]
        max connections = 25
        path = /srv/4/node/
        read only = false
        lock file = /var/lock/object6040.lock
        EOF

        sed -e 's/--no-detach //'      \
            -e 's/cfgfile$/cfgfile"/'  \
            -e '/command_background/d' \
            -e '/RSYNC_OPTS/d'         \
            -i /etc/init.d/rsyncd

        rc-update add rsyncd
        rc-service rsyncd start


        # ==========   [Run memcached]    ==========
        rc-update add memcached
        rc-service memcached start


        # ==========  [Setup Swift Conf]  ==========

        cat << SWIFT_CONF > /etc/swift/swift.conf
        [swift-hash]
        # random unique strings that can never change (DO NOT LOSE)
        # Use only printable chars (python -c "import string; print(string.printable)")
        swift_hash_path_prefix = changeme
        swift_hash_path_suffix = changeme

        [storage-policy:0]
        name = gold
        policy_type = replication
        default = yes

        [storage-policy:1]
        name = silver
        policy_type = replication

        [storage-policy:2]
        name = ec42
        policy_type = erasure_coding
        ec_type = liberasurecode_rs_vand
        ec_num_data_fragments = 4
        ec_num_parity_fragments = 2
        SWIFT_CONF

        # ----------    [Proxy Server]    ----------

        cat << SWIFT_PROXY_SERVER_CONF > /etc/swift/proxy-server.conf
        [DEFAULT]
        bind_port = 8080
        workers = 1
        user = swift
        log_facility = LOG_LOCAL1
        eventlet_debug = true

        [pipeline:main]
        # Yes, proxy-logging appears twice. This is so that
        # middleware-originated requests get logged too.
        pipeline = catch_errors gatekeeper healthcheck proxy-logging cache listing_formats bulk tempurl ratelimit crossdomain container_sync tempauth staticweb copy container-quotas account-quotas slo dlo versioned_writes symlink proxy-logging proxy-server

        [filter:catch_errors]
        use = egg:swift#catch_errors

        [filter:healthcheck]
        use = egg:swift#healthcheck

        [filter:proxy-logging]
        use = egg:swift#proxy_logging

        [filter:bulk]
        use = egg:swift#bulk

        [filter:ratelimit]
        use = egg:swift#ratelimit

        [filter:crossdomain]
        use = egg:swift#crossdomain

        [filter:dlo]
        use = egg:swift#dlo

        [filter:slo]
        use = egg:swift#slo

        [filter:container_sync]
        use = egg:swift#container_sync
        current = //saio/saio_endpoint

        [filter:tempurl]
        use = egg:swift#tempurl

        [filter:tempauth]
        use = egg:swift#tempauth
        user_admin_admin = admin .admin .reseller_admin
        user_test_tester = testing .admin
        user_test2_tester2 = testing2 .admin
        user_test_tester3 = testing3

        [filter:staticweb]
        use = egg:swift#staticweb

        [filter:account-quotas]
        use = egg:swift#account_quotas

        [filter:container-quotas]
        use = egg:swift#container_quotas

        [filter:cache]
        use = egg:swift#memcache

        [filter:gatekeeper]
        use = egg:swift#gatekeeper

        [filter:versioned_writes]
        use = egg:swift#versioned_writes
        allow_versioned_writes = true

        [filter:copy]
        use = egg:swift#copy

        [filter:listing_formats]
        use = egg:swift#listing_formats

        [filter:symlink]
        use = egg:swift#symlink

        # To enable, add the s3api middleware to the pipeline before tempauth
        [filter:s3api]
        use = egg:swift#s3api

        [filter:keymaster]
        use = egg:swift#keymaster
        encryption_root_secret = changeme/changeme/changeme/changeme/change/=

        # To enable use of encryption add both middlewares to pipeline, example:
        # <other middleware> keymaster encryption proxy-logging proxy-server
        [filter:encryption]
        use = egg:swift#encryption

        [app:proxy-server]
        use = egg:swift#proxy
        allow_account_management = true
        account_autocreate = true
        SWIFT_PROXY_SERVER_CONF

        # ----------   [Object Expirer]   ----------

        cat << SWIFT_OBJECT_EXPIRER_CONF > /etc/swift/object-expirer.conf
        [DEFAULT]
        user = swift
        log_name = object-expirer
        log_facility = LOG_LOCAL6
        log_level = INFO

        [object-expirer]
        interval = 300

        [pipeline:main]
        pipeline = catch_errors cache proxy-server

        [app:proxy-server]
        use = egg:swift#proxy

        [filter:cache]
        use = egg:swift#memcache

        [filter:catch_errors]
        use = egg:swift#catch_errors
        SWIFT_OBJECT_EXPIRER_CONF

        # ----------  [Container Recon]   ----------

        cat << SWIFT_CONTAINER_RECONCILER_CONF > /etc/swift/container-reconciler.conf
        [DEFAULT]
        user = swift

        [container-reconciler]

        [pipeline:main]
        pipeline = catch_errors proxy-logging cache proxy-server

        [app:proxy-server]
        use = egg:swift#proxy

        [filter:cache]
        use = egg:swift#memcache

        [filter:proxy-logging]
        use = egg:swift#proxy_logging

        [filter:catch_errors]
        use = egg:swift#catch_errors
        SWIFT_CONTAINER_RECONCILER_CONF

        cat << SWIFT_CONTAINER_SYNC_REALMS_CONF > /etc/swift/container-sync-realms.conf
        [saio]
        key = changeme
        key2 = changeme
        cluster_saio_endpoint = http://127.0.0.1:8080/v1/
        SWIFT_CONTAINER_SYNC_REALMS_CONF

        # ----------   [Servers 1-4...]   ----------

        mkdir -p /etc/swift/account-server /etc/swift/container-server /etc/swift/object-server

        for x in 1 2 3 4; do
        # ----------   [Account Server]   ----------

        echo "writing /etc/swift/account-server/$x.conf..."
        cat << SWIFT_ACCOUNT_SERVER_CONF > /etc/swift/account-server/$x.conf
        [DEFAULT]
        devices = /srv/$x/node
        mount_check = false
        disable_fallocate = true
        bind_ip = 127.0.0.$x
        bind_port = 60${x}2
        workers = 1
        user = swift
        log_facility = LOG_LOCAL$((x + 1))
        recon_cache_path = /var/cache/swift$x
        eventlet_debug = true

        [pipeline:main]
        pipeline = healthcheck recon account-server

        [app:account-server]
        use = egg:swift#account

        [filter:recon]
        use = egg:swift#recon

        [filter:healthcheck]
        use = egg:swift#healthcheck

        [account-replicator]
        rsync_module = {replication_ip}::account{replication_port}

        [account-auditor]

        [account-reaper]
        SWIFT_ACCOUNT_SERVER_CONF

        # ----------  [Container Server]  ----------

        echo "writing /etc/swift/container-server/$x.conf..."
        cat << SWIFT_CONTAINER_SERVER_CONF > /etc/swift/container-server/$x.conf
        [DEFAULT]
        devices = /srv/$x/node
        mount_check = false
        disable_fallocate = true
        bind_ip = 127.0.0.$x
        bind_port = 60${x}1
        workers = 1
        user = swift
        log_facility = LOG_LOCAL$((x + 1))
        recon_cache_path = /var/cache/swift$x
        eventlet_debug = true

        [pipeline:main]
        pipeline = healthcheck recon container-server

        [app:container-server]
        use = egg:swift#container

        [filter:recon]
        use = egg:swift#recon

        [filter:healthcheck]
        use = egg:swift#healthcheck

        [container-replicator]
        rsync_module = {replication_ip}::container{replication_port}

        [container-updater]

        [container-auditor]

        [container-sync]

        [container-sharder]
        auto_shard = true
        rsync_module = {replication_ip}::container{replication_port}
        # This is intentionally much smaller than the default of 1,000,000 so tests
        # can run in a reasonable amount of time
        shard_container_threshold = 100
        # The probe tests make explicit assumptions about the batch sizes
        shard_scanner_batch_size = 10
        cleave_batch_size = 2
        SWIFT_CONTAINER_SERVER_CONF

        # ----------   [Object Server]    ----------

        echo "writing /etc/swift/object-server/$x.conf..."
        cat << SWIFT_OBJECT_SERVER_CONF > /etc/swift/object-server/$x.conf
        [DEFAULT]
        devices = /srv/$x/node
        mount_check = false
        disable_fallocate = true
        bind_ip = 127.0.0.$x
        bind_port = 60${x}0
        workers = 1
        user = swift
        log_facility = LOG_LOCAL$((x + 1))
        recon_cache_path = /var/cache/swift$x
        eventlet_debug = true

        [pipeline:main]
        pipeline = healthcheck recon object-server

        [app:object-server]
        use = egg:swift#object

        [filter:recon]
        use = egg:swift#recon

        [filter:healthcheck]
        use = egg:swift#healthcheck

        [object-replicator]
        rsync_module = {replication_ip}::object{replication_port}

        [object-reconstructor]

        [object-updater]

        [object-auditor]
        SWIFT_OBJECT_SERVER_CONF
        done

        chown -R swift:swift /etc/swift

        # ----------    [Build Rings]     ----------

        rm -f /etc/swift/*.builder /etc/swift/*.ring.gz /etc/swift/backups/*.builder /etc/swift/backups/*.ring.gz

        su swift -c "cd /etc/swift; swift-ring-builder object.builder create 10 3 1"
        su swift -c "cd /etc/swift; swift-ring-builder object.builder add r1z1-127.0.0.1:6010/sdb1 1"
        su swift -c "cd /etc/swift; swift-ring-builder object.builder add r1z2-127.0.0.2:6020/sdb2 1"
        su swift -c "cd /etc/swift; swift-ring-builder object.builder add r1z3-127.0.0.3:6030/sdb3 1"
        su swift -c "cd /etc/swift; swift-ring-builder object.builder add r1z4-127.0.0.4:6040/sdb4 1"
        su swift -c "cd /etc/swift; swift-ring-builder object.builder rebalance"
        su swift -c "cd /etc/swift; swift-ring-builder object-1.builder create 10 2 1"
        su swift -c "cd /etc/swift; swift-ring-builder object-1.builder add r1z1-127.0.0.1:6010/sdb1 1"
        su swift -c "cd /etc/swift; swift-ring-builder object-1.builder add r1z2-127.0.0.2:6020/sdb2 1"
        su swift -c "cd /etc/swift; swift-ring-builder object-1.builder add r1z3-127.0.0.3:6030/sdb3 1"
        su swift -c "cd /etc/swift; swift-ring-builder object-1.builder add r1z4-127.0.0.4:6040/sdb4 1"
        su swift -c "cd /etc/swift; swift-ring-builder object-1.builder rebalance"
        su swift -c "cd /etc/swift; swift-ring-builder object-2.builder create 10 6 1"
        su swift -c "cd /etc/swift; swift-ring-builder object-2.builder add r1z1-127.0.0.1:6010/sdb1 1"
        su swift -c "cd /etc/swift; swift-ring-builder object-2.builder add r1z1-127.0.0.1:6010/sdb5 1"
        su swift -c "cd /etc/swift; swift-ring-builder object-2.builder add r1z2-127.0.0.2:6020/sdb2 1"
        su swift -c "cd /etc/swift; swift-ring-builder object-2.builder add r1z2-127.0.0.2:6020/sdb6 1"
        su swift -c "cd /etc/swift; swift-ring-builder object-2.builder add r1z3-127.0.0.3:6030/sdb3 1"
        su swift -c "cd /etc/swift; swift-ring-builder object-2.builder add r1z3-127.0.0.3:6030/sdb7 1"
        su swift -c "cd /etc/swift; swift-ring-builder object-2.builder add r1z4-127.0.0.4:6040/sdb4 1"
        su swift -c "cd /etc/swift; swift-ring-builder object-2.builder add r1z4-127.0.0.4:6040/sdb8 1"
        su swift -c "cd /etc/swift; swift-ring-builder object-2.builder rebalance"
        su swift -c "cd /etc/swift; swift-ring-builder container.builder create 10 3 1"
        su swift -c "cd /etc/swift; swift-ring-builder container.builder add r1z1-127.0.0.1:6011/sdb1 1"
        su swift -c "cd /etc/swift; swift-ring-builder container.builder add r1z2-127.0.0.2:6021/sdb2 1"
        su swift -c "cd /etc/swift; swift-ring-builder container.builder add r1z3-127.0.0.3:6031/sdb3 1"
        su swift -c "cd /etc/swift; swift-ring-builder container.builder add r1z4-127.0.0.4:6041/sdb4 1"
        su swift -c "cd /etc/swift; swift-ring-builder container.builder rebalance"
        su swift -c "cd /etc/swift; swift-ring-builder account.builder create 10 3 1"
        su swift -c "cd /etc/swift; swift-ring-builder account.builder add r1z1-127.0.0.1:6012/sdb1 1"
        su swift -c "cd /etc/swift; swift-ring-builder account.builder add r1z2-127.0.0.2:6022/sdb2 1"
        su swift -c "cd /etc/swift; swift-ring-builder account.builder add r1z3-127.0.0.3:6032/sdb3 1"
        su swift -c "cd /etc/swift; swift-ring-builder account.builder add r1z4-127.0.0.4:6042/sdb4 1"
        su swift -c "cd /etc/swift; swift-ring-builder account.builder rebalance"

        # ==========     [Run Swift]      ==========

        su swift -c "swift-init start main"

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

        echo "listen_addresses = '*'" >> /var/lib/postgresql/9.5/data/postgresql.conf
        echo "host all all 192.168.50.10/0 md5" >> /var/lib/postgresql/9.5/data/pg_hba.conf
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
