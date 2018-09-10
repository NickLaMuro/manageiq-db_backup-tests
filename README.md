Purpose
-------

This is a `Vagrantfile` and test script that is intended to setup a
reproducible environment with an `appliance` VM and a `share` VM.  Those roles
of the VMs are as follows:

- The `appliance` VM is a MIQ appliance with the actually workers shut down,
  but preloaded with a dummy set of data that can be exported.  It also
  includes a test script that can be used as a smoke test for all of the
  database backup/dumping strategies.
- The `share` VM is a light appliance that is currently configured to be both
  an NFS and SMB share for the `appliance`.  It is configured to give
  permission to the `appliance` VM those to connect via SMB and NFS at some
  dummy mount points.

The test script will then run a suite of all of the backup/dump strategies and
confirm file integrity of the dumped files for local, NFS, and SMB strategies.


Setup
-----

1. Copy the `Vagrantfile` and the `smoketest_db_tasks.rb` into a directory that is
   on the same level as the following repos:
   * https://github.com/ManageIQ/manageiq
   * https://github.com/ManageIQ/manageiq-gems-pending
   * https://github.com/ManageIQ/manageiq-appliance_console
   * https://github.com/ManageIQ/awesome_spawn
   
   The resulting directory structure should look something like this:
   
   ```
   ├── dir_for_this_code
   │   ├── Vagrantfile
   │   └── smoketest.rb
   ├── manageiq
   │   ...
   ├── manageiq-gems-pending
   │   ...
   ├── manageiq-appliance_console
   │   ...
   └── awesome_spawn
   ```
   
2. In the directory with the `Vagrantfile`, run: 
   
   ```console
   $ vagrant up
   $ vagrant ssh appliance
   appliance $ vmdb
   appliance $ sudo /bin/sh -c "source /etc/profile.d/evm.sh; bin/rails r tmp/bz_1592480_db_replication_script.rb"
   appliance $ exit
   ```
   
3. To run the test, run the following:
   
   ```console
   $ vagrant ssh appliance -c "sudo -i ruby /vagrant/tests/smoketest.rb"
   ```

This does assume that the following pull requests have been merged for the
smoke tests to succeed:

- https://github.com/ManageIQ/awesome_spawn/pull/41
- https://github.com/ManageIQ/manageiq/pull/17549
- https://github.com/ManageIQ/manageiq/pull/17652
- https://github.com/ManageIQ/manageiq-gems-pending/pull/356

If they aren't merged, you can run the following to get that code in place:

```console
$ CWD=$(pwd)
$ cd ../manageiq
$ git apply <(curl -L https://github.com/ManageIQ/manageiq/pull/17549.patch)
$ git apply <(curl -L https://github.com/ManageIQ/manageiq/pull/17652.patch)
$ cd ../awesome_spawn
$ git apply <(curl -L https://github.com/ManageIQ/awesome_spawn/pull/41.patch)
$ cd ../manageiq-gems-pending
$ git apply <(curl -L https://github.com/ManageIQ/manageiq-gems-pending/pull/356.patch)
$ cd $CWD
```

And then to setup the VMs to have this code, run the following:

```console
$ vagrant rsync
$ vagrant provision appliance
```


### S3 environment variable setup

You will need a `.env` file in the directory with the following:

```bash
AWS_REGION="us-east-1"
AWS_ACCESS_KEY_ID=[YOUR_ACCESS_KEY_ID_HERE]
AWS_SECRET_ACCESS_KEY=[YOUR_SECRET_ACCESS_KEY_HERE]
```


Creating and testing FileDepots
-------------------------------

### Creating and Testing NFS

```console
$ vagrant ssh appliance
appliance(vagrant) $ vmdb
appliance(vagrant) $ sudo --shell
appliance(root) $ bin/rails c
irb> task = MiqTask.create
irb> file_depot = FileDepotNfs.create(:uri => "nfs://192.168.50.11")
irb> MiqServer.my_server.log_file_depot = file_depot
irb> MiqServer.my_server.save
irb> MiqServer.my_server.post_current_logs(task.id, file_depot)
```


### Creating and Testing SMB

```console
$ vagrant ssh appliance
appliance(vagrant) $ vmdb
appliance(vagrant) $ sudo --shell
appliance(root) $ bin/rails c
irb> task = MiqTask.create
irb> smb_auth = Authentication.new(:userid => "vagrant", :password => "vagrant")
irb> file_depot = FileDepotSmb.create(:uri => "smb://192.168.50.11/share", :authentications => [smb_auth])
irb> MiqServer.my_server.log_file_depot = file_depot
irb> MiqServer.my_server.save
irb> MiqServer.my_server.post_current_logs(task.id, file_depot)
```


TROUBLESHOOTING
---------------

* **If most of the tests for splits are failing:**
  
  Chances are in this case the appliance might still be running, causing not
  only a decent delay in the tests between a non-split backup (where the base
  size for the backup is derived) and the split version, which gives the DB
  backup more time to grow in size because of split CPU resources, but also
  extra log statements are created from general appliance actions, causing the
  size to be bigger as well.
  
  Run the following to check if the appliance is still running:
  
  ```console
  $ vagrant ssh appliance -c "sudo systemctl status evmserverd"
  ```
  
  And if it is, run:
  
  ```console
  $ vagrant ssh appliance -c "sudo systemctl stop evmserverd"
  $ vagrant ssh appliance -c "sudo systemctl disable evmserverd"
  ```

* **If split backup tests are failing**
  
  As much as I have done to try an mitigate this, it does happen from time to
  time.
  
  I think part of it is that when you wait to run tests for a while, the
  database log might get "back logged", and cause a considerable amount extra
  bytes to exist on the DB log.
  
  Another alternative (facts) theory is that `postgresql`/the appliance
  database configuration might have decided to run a background task just after
  you were running the previous test and caused the `split backup` test in
  question to be much larger.
  
  Try re-running and seeing if it passes.  These tests with the backup aren't
  fool proof since they just checking that they byte size of the file is
  "mostly" the same since it is quicker than reloading the DB... though we do
  now do that....

* **`Aws::S3::Errors::RequestTimeTooSkewed`**
  
  You might get this if your VM has been turned on in between shutting of your
  laptop lid, or other causes.
  
  Best to just restart the VMs with a `vagrant halt && vagrant up`


TODO
----

- [x] Setup test script to reload the dumps to a dummy DB, and confirm proper
  table sizes with the original.
- [x] Test `appliance_console` commands (backup & dump)
- [x] Test database restore
- [x] Test table exclusions
- [x] Test s3
