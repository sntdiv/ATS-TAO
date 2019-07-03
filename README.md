# ATS-TAO
New TAO Build Script for installation on Centos 7

# Files for TAO 3.2 installation

The TAO-Centos7 install script should be copied down to the server and run as root. It will pull the rest of the GIT files down and copy them to thier respectable locations.

The TAO_Centos7_Install.sh file does the following:
- Yum update
- Set's timezone to New_York
- Sets up epel-release repository
- Adds a non-root user of your choice to the system
- Enables auto-updates via cron
- Sets up system hostname
- Other admin tasks
- SSH/Firewall setup
- LAMP server install w/ PHP 7.1 (remi)
- Apache configurations uploaded
- TAO 3.2 Release Candidate 2 Installation

# Instructions
1. Download TAO_Centos7_Install.sh to /root directory and make it executable (chmod +x TAO_Centos7_Install.sh)
2. Run the scrpit:  (./TAO_Centos7_Install.sh)
3. Provide input where needed
    -- new username / password
    -- SQL setup (no root password set, so press <Enter> when asked. Setup new root user and password. You will need this for TAO config.
4. Reboot and browse to the http://<servername>/tao/install directory and configure the TAO settings.
5. Profit!
