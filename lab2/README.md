# Lab 2

Instructions for this section will be provided in class and on Blackboard when we reach it.

Put your work for Lab 2 in this folder
The deployment steps, in order:'deploy-web.sh' first installs Python 3 using 'dnf'. Then, it creates the 'acs730web' service user if it does not already exist. After that, it creates '/opt/acs730-web' and creates the 'index.html' file for the web application. It sets the application directory ownership to 'acs730web', copies the 'acs730-web.service' systemd unit file to '/etc/systemd/system/', reloads systemd, enables the service to start automatically after reboot, and restarts the service. Finally, it checks that the web application is running by using 'curl' on 'localhost'.

'systemctl start' vs. 'systemctl enable':'systemctl start' starts the service now, while 'systemctl enable' makes the service start automatically when the system boots.

SSH vs. HTTP:SSH is restricted to a '/32' because SSH access should only be allowed from my own IP address, while HTTP is open to '0.0.0.0/0' because the web application needs to be accessible from the internet.

Application user:The application runs as 'acs730web', not root. Running the application as a separate non-root service user follows the principle of least privilege, so if the web application is compromised, it does not have full root access to the server.

## Experiments

1. Start without enable

Prediction: I expect the website to be running before the reboot because systemctl disable only removes the service from starting automatically at boot. After the reboot, I expect curl to fail because the service will not start automatically, and systemctl status should show that the service is inactive.

What I ran: I disabled the service, checked its active status, rebooted the workstation, and checked the website and service status again. After the test, I enabled the service again.

What I saw: Before the reboot, the website was still running because disabling the service does not stop a service that is already running. After the reboot, the website was not available and the service was inactive because it was disabled and did not start during boot. I then re-enabled the service.

2. Drop the capability

Prediction: I expect the service to fail after removing AmbientCapabilities=CAP_NET_BIND_SERVICE because the application runs as the non-root acs730web user and port 80 is a privileged port.

What I ran: I commented out the AmbientCapabilities line, ran daemon-reload, restarted the service, and then checked the journal with journalctl -u acs730-web -n 20.

What I saw: The service failed because the acs730web user did not have permission to bind to port 80. This shows why web servers historically started as root: root could bind to privileged ports such as port 80, although running the whole application as root creates a larger security risk.

3. Tighten HTTP

Prediction: I expect curl from the workstation to fail because the security group will only allow port 80 from my laptop's public IP address. The website should still load in my laptop's browser because my laptop's IP address is the address allowed by the security group.

What I ran: I removed the 0.0.0.0/0 rule for port 80 and added a rule allowing HTTP only from my laptop's public IP address with /32. I checked my public IP from my laptop using curl -s https://checkip.amazonaws.com, then tested the website from both the workstation and my laptop browser.

What I saw: The request from the workstation was blocked because its public source IP was not the IP allowed by the security group. The page still loaded from my laptop because its public IP matched the /32 rule. This shows that the security group checks the source IP of the incoming connection, not whether the request is coming from the EC2 instance itself.

4. Run it as root

Prediction: I expect the website to continue working after changing User=acs730web to User=root because root has permission to bind to port 80 without the additional capability.

What I ran: I changed the service to User=root, ran daemon-reload, restarted the service, and checked the running process with ps -o user,cmd -C python3. I also checked the application files with ls -l /opt/acs730-web.

What I saw: The Python web server was running as root, while the application files were still in /opt/acs730-web. If an attacker found a vulnerability in the web application while it was running as root, the attacker could potentially gain root-level access to the server; when it runs as acs730web, the attacker's access is limited to the permissions available to that service user.

5. Break the idempotency

Prediction: I expect the second run of deploy-web.sh to fail at the useradd line because the acs730web user already exists. Because the script uses set -e, the script should stop immediately when that command fails.

What I ran: I removed the if ! id -u guard and ran deploy-web.sh twice.

What I saw: The first run created the acs730web user successfully, but the second run failed when useradd tried to create the same user again. Because set -e was enabled, the script stopped after the failure instead of continuing with the remaining deployment steps. This shows why a deployment script should be safe to run more than once, especially when a deployment needs to be repeated after an update or a failure.
