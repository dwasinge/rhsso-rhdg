#!/bin/bash

# source the properties:
. properties/rhdg-cluster-script.properties

BASE_DIR=$PWD
REGION=$region
BINARIES_DIR=$binarydir
WORK_DIR=$workingdir
PATCH_DIR=$patchdir
DELIVERABLE_DIR=$outdir
TARGET_WORK_DIR=$dgdir
BINARY_FILE_NAME=$binaryname
PATCH_FILE_NAME=$patchname
IS_PATCH_AVAILALE=$isPatchAvailable
RHDG_HOME=$BASE_DIR/$WORK_DIR/$TARGET_WORK_DIR
ADMIN_USER=$adminuser
ADMIN_PASSWORD=$adminpassword

INSTALL_NATIVE_S3_PING=$installnatives3ping
NATIVE_S3_PING_ARTIFACT=$natives3artifact
NATIVE_S3_PING_VERSION=$natives3version

DEBUG=$debug

echo "************************* DEBUG SCRIPT ENVIRONMENT *********************************"

if [ $DEBUG == 'true' ];
then

    echo SCRIPT ENVIRONMENT:
    echo region:                $REGION
    echo binary directory:      $BINARIES_DIR
    echo work directory:        $WORK_DIR
    echo patch directory:       $PATCH_DIR
    echo deliverable directory: $DELIVERABLE_DIR
    echo target work directory: $TARGET_WORK_DIR
    echo binary file name:      $BINARY_FILE_NAME
    echo patch file name:       $PATCH_FILE_NAME
    echo is patch available:    $IS_PATCH_AVAILALE
    echo RHDG HOME:             $RHDG_HOME
    echo ADMIN USER:            $ADMIN_USER
    echo ADMIN PASSWORD:        $ADMIN_PASSWORD
    echo Native Ping Version:   $NATIVE_S3_PING_VERSION
    echo Install Native Ping:   $INSTALL_NATIVE_S3_PING
fi

echo "************************* VALIDATING PRE-REQUISITES *********************************"

# validate required commands (git, maven)
if [ $INSTALL_NATIVE_S3_PING == 'true' ];
then

echo "  >>>> Validating Git is Installed <<<< "
command -v git >/dev/null 2>&1 ||
{ echo >&2 "Git is not installed.";
  exit
}

echo "  >>>> Validating Maven is Installed <<<< "
command -v mvn >/dev/null 2>&1 ||
{ echo >&2 "Maven is not installed.";
  exit
}

fi 

echo "************************* START CONFIGURING RH RHDG BINARIES *********************************"

echo "  >>>> EXTRACTING BINARIES <<<< "

cp $BINARIES_DIR/$BINARY_FILE_NAME $WORK_DIR/
unzip $WORK_DIR/$BINARY_FILE_NAME -d $WORK_DIR/

echo "  >>>> ADDING DEFAULT ADMIN USER <<<< "

$RHDG_HOME/bin/cli.sh user create $ADMIN_USER -p $ADMIN_PASSWORD -g admin

echo "  >>>> Replacing server configurations with custom configurations  <<<< "

rm -rf $RHDG_HOME/server/conf/infinispan.xml

if [ $INSTALL_NATIVE_S3_PING == 'true' ];
then

echo copying configurations/infinispan-$REGION-native-s3-ping.xml to $RHDG_HOME/server/conf/infinispan.xml
cp configurations/infinispan-$REGION-native-s3-ping.xml $RHDG_HOME/server/conf/infinispan.xml

else

echo copying configurations/infinispan-$REGION.xml to $RHDG_HOME/server/conf/infinispan.xml
cp configurations/infinispan-$REGION.xml $RHDG_HOME/server/conf/infinispan.xml

fi

echo "  >>>> Replacing service with custom configurations  <<<< "

rm -rf $RHDG_HOME/docs/systemd/infinispan.service
cp configurations/infinispan.service $RHDG_HOME/docs/systemd/infinispan.service

echo "  >>>> Add startup properties file  <<<< "

cp properties/rhdg-startup.properties $RHDG_HOME/rhdg-starup.properties

# move to working directory
cd $BASE_DIR/$WORK_DIR

if [ $INSTALL_NATIVE_S3_PING == 'true' ];
then

echo "  >>>> Installing AWS EC2 Ping Dependencies <<<< "

# clone s3 ping repo
git clone https://github.com/jgroups-extras/native-s3-ping.git
# checkout configured version
cd $NATIVE_S3_PING_ARTIFACT
git checkout $NATIVE_S3_PING_ARTIFACT-$NATIVE_S3_PING_VERSION
# copy ping artifacts with associated dependencies
mvn dependency:copy -Dartifact=org.jgroups.aws.s3:$NATIVE_S3_PING_ARTIFACT:$NATIVE_S3_PING_VERSION -DoutputDirectory=$RHDG_HOME/server/lib
mvn dependency:copy-dependencies -DoutputDirectory=$RHDG_HOME/server/lib -DincludeScope=runtime -DexcludeGroupIds=org.jgroups,com.fasterxml.jackson.core,com.fasterxml.jackson.dataformat,org.apache.logging.log4j

fi

echo "  >>>> Clean and package the custom binaries  <<<< "

cd $BASE_DIR/$WORK_DIR

rm $BINARY_FILE_NAME

zip -r ../deliverable/rhdg-$REGION.zip $TARGET_WORK_DIR

rm -rf $TARGET_WORK_DIR
rm -rf native-s3-ping