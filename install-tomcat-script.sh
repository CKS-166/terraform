#!/bin/bash

#use this command to resolve /r error sed -i 's/\r$//' filename

# Define the Tomcat version and download URL
TOMCAT_VERSION="9.0.80"
TOMCAT_URL="https://dlcdn.apache.org/tomcat/tomcat-9/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz"

# Define the installation directory
INSTALL_DIR="/opt/tomcat"

# Check if Java is installed
if ! command -v java &>/dev/null; then
  echo "Java is not installed. Please install Java and try again."
  exit 1
fi

# Create the installation directory if it doesn't exist
sudo mkdir -p $INSTALL_DIR

# Download Tomcat
wget -q -O /tmp/apache-tomcat.tar.gz $TOMCAT_URL

# Extract and install Tomcat
sudo tar xzf /tmp/apache-tomcat.tar.gz -C $INSTALL_DIR --strip-components=1

# Create a symbolic link to the Tomcat installation directory
sudo ln -s $INSTALL_DIR /opt/tomcat-latest

# Create a Tomcat service user and group
sudo groupadd tomcat
sudo useradd -s /bin/false -g tomcat -d $INSTALL_DIR tomcat

# Set ownership and permissions
sudo chown -R tomcat:tomcat $INSTALL_DIR
sudo chmod -R 755 $INSTALL_DIR

# Create a systemd service file
cat <<EOL | sudo tee /etc/systemd/system/tomcat.service
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking
ExecStart=$INSTALL_DIR/bin/startup.sh
ExecStop=$INSTALL_DIR/bin/shutdown.sh
User=tomcat
Group=tomcat
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL

# Configure tomcat-users.xml
cat <<EOL | sudo tee /opt/tomcat/conf/tomcat-users.xml
<?xml version="1.0" encoding="UTF-8"?>
<tomcat-users xmlns="http://tomcat.apache.org/xml"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:schemaLocation="http://tomcat.apache.org/xml tomcat-users.xsd"
              version="1.0">
  <role rolename="manager-gui"/>
  <user username="manager" password="mpassword" roles="manager-gui"/>
  <role rolename="admin-gui"/>
  <user username="admin" password="apassword" roles="manager-gui,admin-gui"/>
</tomcat-users>
EOL

# Configure context.xml for manager app
sudo sed -i 's/<Valve/<\!--<Valve-->/' /opt/tomcat/webapps/manager/META-INF/context.xml

# Configure context.xml for host-manager app
sudo sed -i 's/<Valve/<\!--<Valve-->/' /opt/tomcat/webapps/host-manager/META-INF/context.xml

# Reload systemd
sudo systemctl daemon-reload

# Start Tomcat service
sudo systemctl start tomcat

# Enable Tomcat to start on boot
sudo systemctl enable tomcat

# Clean up
rm /tmp/apache-tomcat.tar.gz

echo "Apache Tomcat ${TOMCAT_VERSION} has been installed to ${INSTALL_DIR}."
echo "Tomcat service is now running."
