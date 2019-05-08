Purpose
-------

This is a `Vagrantfile` and test script that is intended to setup a
reproducible environment with an `appliance` VM and a `share` VM.  Those roles
of the VMs are as follows:

- The `appliance` VM is a MIQ appliance with the actually workers shut down,
  but preloaded with a dummy set of data that can be exported.  It also
  includes a test script that can be used as a smoke test for all of the
  database backup/dumping strategies.
- The `share` VM is a light appliance that is currently configured to be an `NFS`
  `SMB`, and `FTP` share for the `appliance`.  It is configured to give
  permission to the `appliance` VM those to connect via SMB and NFS at some
  entry points (it also set up a swift instance, but that currently isn't
  configured properly to work)

The test script will then run a suite of all of the backup/dump strategies and
confirm file integrity of the dumped files for all strategies (local, `NFS`,
`SMB`, `FTP`, `s3` and `Swift` .


Usage
-----

### Quick start

Run `rake test` and things should #JustWork™

The task should handle setting up your `.env` file for you with the needed
credentials for s3 and swift testing (currently both require a remote instance
for testing to happen), spin up the environment, seed, and run the specs.  The
tasks are configured to be as omnipotent as possible (within reason), so they
should be limited amounts wasted time checking for "dependencies" (running VMs,
checking for seeding, etc.)


### Setup (long version)

The main steps that are done on first run of `rake test` are as follows:

1. Run `rake .env`, which is a `Rake::FileTask` that configures the `.env` with
   `s3` and `swift` credentials which are needed to run those specs currently.
   You can opt out of those tests by running `rake test` with the following:
   
       $ rake test:no_s3 test:no_swift test
   
   Which will skip any setup and tests for `s3` (ideally...)
   
2. Run `rake start` which effectively runs `vagrant up` for you.  This task
   does do some VirtualBox "shell outs" to check if the `vms` are running
   first, so this will be a snappy task if nothing needs to be done.
   
3. Run `rake seed`, which is an ssh task to the box that triggers the seed
   script that is provisioned into the box (see the `Vagrantfile` for more
   details).  This task is a little slower even on subsequent runs since it
   requires running a `bin/rails` on the box (and that is just slow), but it is
   configure to short circut once it has one once, so it is only a minor delay
   the subsequent calls.
   
4. `rake test` proper is run, which runs the following SSH command on the
   `appliance` vm:
   
       $ vagrant ssh appliance -c "sudo -i ruby /vagrant/tests/smoketest.rb --clean [EXTRA_ARGS]"
    
    As mentioned above, the `EXTRA_ARGS` comes from the `test:no_s3` and
    `test:no_swift` tasks if applied, and `--clean` can be opted out of if
    `test:no_clean` is passed.  Under the covers this is just mutating a
    instance variable in the Rakefile, so these tasks need to be run prior to
    the main `test` task to be populated in the command correctly.


Old Setup (outdated)
--------------------

Leaving this here for reference, but since we are now using a hammer build for
the appliance, most of the code necessary to run things is included with the
base image.

### Steps

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
  
* **If split backup tests are _still_ failing**
  
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
  
* **The first test is running indefinitely**
  
  I haven't been able to narrow this one down yet, but it seems like restarting
  the test suite fixes this issue, and it only seems to happen on the first run
  of the suite after the VM has booted.
  
  Any ideas as to _**WHY**_ this behavior is occurring would be appreciated,
  but my guess is no one is actually reading this anyway... so I am probably on
  my own for this one.
  
* **`Aws::S3::Errors::RequestTimeTooSkewed`**
  
  You might get this if your VM has been turned on in between shutting of your
  laptop lid, or other causes (the VMs are setup to re-sync the internal clock
  on resume).
  
  Best to just restart the VMs with a `vagrant halt && vagrant up`
