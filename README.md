# Bugzilla vagrant

A Vagrant setup to install Bugzilla on Ubuntu with Apache. To use this
with vagrant installed, clone this repository and run `vagrant up`.

The installation script could also be used on a non-vagrant system to
simplify the installation of Bugzilla however the response file would require
modification to use a real SMTP server and switching to a real database
as this is configured to use Sqlite for development.

If any patch files are included in the patches folder then these will be
applied using `git am`.

If any Bugzilla extensions are included as zip archives in the
extensions folder then these are unpacked in the Bugzilla extensions
folder on the server before 'checksetup.pl' is run.

*Note* this installation uses SQLite as the database to simplify the
 installation. This should not be used for production installations.

Once the provisioning stage has completed the Bugzilla application
will be running and just needs logging in as `admim` using
password `password` (can be changed in the install-bugzilla.sh file).

The box exports the guest port 80 to localhost port 8080 so the final
URL to access your Bugzilla application will be:

    http://localhost:8080/Bugzilla/
