# Overview

This repository can be used to configure a Red Hat Data Grid or Infinispan distribution.

# Directory Structure

* `binaries` - contains the zip distribution of data grid or infinispan
* `configurations` - contains infinispan.xml files for different configurations
* `deliverables` - contains the final zip distribution after configured
* `properties` - contains the properties files to configure the script
* `workingdir` - used during script execution to configure the distribution
* `scripts` - init.d configuration and service script

# Scripts

The script `rhdg-cluster-script.sh` is used to add an initial admin user and configure the base distribution.

# How to use it

* Clone this Git repository.
* Download the Data Grid distribution
* Copy the Data Grid distribution to the binaries directory of the cloned repository
* Edit properties in `properties/rhdg-cluster-script.properties`
* Execute `./rhdg-cluster-script.sh`

The result will be a ZIP containing the configured distribution and can be found in the `deliverables` directory.

# Script Configuration

## Script Setup

| Property Name | Default | Description |
|------|---------------|----------|
| `binaryname` | none | name of the data grid distribution in the binaries directory |
| `region` | none | specifies the region and the associated configuration in the configurations directory |
| `debug` | false | will print script environment info during execution |

## Directory Properties

| Property Name | Default | Description |
|------|---------------|----------|
| `workingdir` | workingdir | directory where the script should use as temporary storage |
| `outdir` | deliverable | directory where the final artifact will be placed |
| `binarydir` | binaries | directory where the input data grid distribution will be found |
| `dgdir` |  | data grid home directory |

## Default User Properties

| Property Name | Default | Description |
|------|---------------|----------|
| `adminuser` | admin | default admin user to create |
| `adminpassword` | admin123! | password for default admin user |

## Native S3 Ping Properties

| Property Name | Default | Description |
|------|---------------|----------|
| `natives3artifact` | native-s3-ping | Maven artifact name of the native s3 ping library |
| `natives3version` | 1.0.0.Final | Maven artifact version of the native s3 ping library |
| `installnatives3ping` | false | Flag to add native s3 ping libraries to data grid |

# Running as a Service

## Linux Distributions using systemctl

The `infinispan.service` script can be located in `RHDG_HOME/docs/systemd`.

### Configure service

Set the `INFINISPAN_HOME` environment variable and set the `User`.

### Copy service file to /etc/systemd/system

```
sudo RHDG_HOME/docs/systemd/infinispan.service /etc/systemd/system
```

### Load and Start

```
# reload services in daemon
systemctl daemon-reload

# Activate
systemctl start|enable infinispan

# Check status
systemctl status infinispan

```

## Linux Distributions using init.d

The `infinispan-server.conf` and `infinispan-server.sh` files can be found in the `scripts/init.d` directory of this repository or in the `RHDG_HOME/bin/init.d` directory of the configured distribution created by running `./rhdg-cluster-script.sh`.

### Configure the configuration file `infinispan-server.conf`

```
# Set to process owner user
ISPN_SERVER_USER=ec2-user

# Set to Data Grid (Infinispan) installation directory
ISPN_SERVER_HOME=/home/ec2-user/redhat-datagrid-8.2.1-server

# Set the path of the rhdg-startup.properties in the installation directory
ISPN_OPTS="-P /home/ec2-user/redhat-datagrid-8.2.1-server/rhdg-startup.properties"
```

### Copy the configuration file to /etc

```
sudo cp RHDG_HOME/bin/init.d/infinispan-server.conf /etc/infinispan-server
```

### Copy the service script to /etc/init.d

```
# copy the service script
sudo cp RHDG_HOME/bin/init.d/infinispan-server.sh /etc/init.d
# set permissions on script file
sudo chmod +x /etc/init.d/infinispan-server.sh
```

### Add script to automatically started services

```
sudo chkconfig --add infinispan-service.sh
```

### Use service to control the server

```
sudo service infinispan-service [start|restart|stop|status]
```