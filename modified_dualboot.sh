# This code is modified and the original source of the code is unknown. THis dualboot.sh file works for only Nexus 4. 
# Please reverse engineer this code and make this code for work for different devices
# Author: Revanth Pobala.


#!/bin/bash

ACTION=$1
SCRIPT_NAME=dualboot.sh
# Used version of CWM recovery
URL_CMW_PATH_MAKO="https://dl.dropbox.com/sh/sykai3iuexr1d67/d2Cn_URd3F/mako.img?retrieve=0"
URL_SUPERU_1_86="http://download.chainfire.eu/372/SuperSU/UPDATE-SuperSU-v1.86.zip?retrieve_file=1"
URL_U_INSTALLER_PACKAGE="https://dl.dropbox.com/s/mf4k2rms9w1aqmh/UPDATE-UbuntuInstaller.zip"
CACHE_RECOVERY=/cache/recovery
TEMP_FOLDER=humpTemp
RECOVERY_IMAGE=recovery.img
SU_PACKAGE=UPDATE-SuperSU-v1.86.zip
#UBUNTU_INSTALLER_PACKAGE=UPDATE-UbuntuInstaller.zip
RECOVERY_URL=” https://dl.dropbox.com/sh/sykai3iuexr1d67/d2Cn_URd3F/mako.img?retrieve=0”
DEVICE=$(adb wait-for-device shell getprop ro.product.device)
CM_DEVICE=$(adb wait-for-device shell getprop ro.cm.device)
    echo "Detected connected Nexus 4"
    RECOVERY_URL=$URL_CMW_PATH_MAKO
  


print_usage() {
  echo "Welcome to the new dualboot installer. This is Ubuntu-Android dualboot enabler"
  echo "Please connect supported phone with adb enabled"
  echo " "
  echo "$SCRIPT_NAME action"
  echo " "
  echo "  actions:"
  echo "    HELP: Prints this help"
  echo "    FULL: Full installation: this will install SuperUser package as well Ubuntu dualboot installer."
  echo "         Use this if you don't have SuperUser package installed on your device."
  echo "         Installation will reboot twice into the recovery, if prompterd **** when exiting recovery, answer NO"
  echo "         Use this option if you already have Ubuntu dualboot installer installed and are only upgrading"
  echo "         Installation will reboot twice into the recovery, if prompterd when existing recovery, answer NO"
  echo "    INSTALL_SU: Installs Superuser"
}

wait_for_adb() {
  MODE=$1
  echo "Waiting for $MODE to boot"
  RECOVERY_STATE=$(adb devices)
  while ! [[ "$RECOVERY_STATE" == *$MODE ]]
  do
    sleep 1
    RECOVERY_STATE=$(adb devices)
  done
}

print_ask_help() {
  echo "For more information refer to $ $SCRIPT_NAME HELP"
}

create_temp_dir() {
  mkdir $TEMP_FOLDER
  cd $TEMP_FOLDER
}

delete_temp_dir() {
  cd ..
  rm -rf $TEMP_FOLDER
}

download_su_package() {
  echo "Downloading Super User package"
  # check downloaded file size, this often fails, so retry. Expected size is 1184318
  download_file $URL_SUPERU_1_86 $SU_PACKAGE 1184000
}

download_app_update() {
  echo "Downloading Ubuntu Installer application package"
  # check downloaded file size, this often fails, so retry. Expected size is 2309120
  download_file $URL_U_INSTALLER_PACKAGE $UBUNTU_INSTALLER_PACKAGE 2309000
}

download_recovery() {
  echo "Downloading recovery for $DEVICE"
  # check downloaded file size, this often fails, so retry. any recovery should be more than 5M
  download_file $RECOVERY_URL $RECOVERY_IMAGE 5000000
}

download_file() {
    DOWNLOAD_URL=$1
    FILENAME=$2
    TARGET_SIZE=$3
    SIZE=1
    # check downloaded file size, this often fails, so retry. Expected size is TARGET_SIZE
    while [[ $TARGET_SIZE -ge $SIZE ]]
    do
        curl $DOWNLOAD_URL > $FILENAME
        SIZE=$(ls -la $FILENAME | awk '{ print $5}')
        echo "Downloaded file has size: $SIZE"
    done
}

install_su() {
    echo "Rebooting to bootloader"
    adb wait-for-device reboot bootloader
    fastboot boot $RECOVERY_IMAGE
    wait_for_adb recovery
    echo "Creating update command"
    adb shell rm -rf $CACHE_RECOVERY
    adb shell mkdir $CACHE_RECOVERY
    adb shell "echo -e '--sideload' > $CACHE_RECOVERY/command"
    echo "Booting back to bootloader"
    adb reboot bootloader
    fastboot boot $RECOVERY_IMAGE
    wait_for_adb sideload
    adb sideload $SU_PACKAGE
    echo "Wait for installation of package to complete"
}

install_ubuntu_installer() {
    echo "Rebooting to bootloader"
    adb wait-for-device reboot bootloader
    fastboot boot $RECOVERY_IMAGE
    wait_for_adb recovery
    echo "Creating update command"
    adb shell rm -rf $CACHE_RECOVERY
    adb shell mkdir $CACHE_RECOVERY
    adb shell "echo -e '--sideload' > $CACHE_RECOVERY/command"
    echo "Booting back to bootloader"
    adb reboot bootloader
    fastboot boot $RECOVERY_IMAGE
    wait_for_adb sideload
    adb sideload $UBUNTU_INSTALLER_PACKAGE
    echo "Wait for installation of package to complete"
    echo "If you are asked to preserve possibly lost root access"
    echo "Or if device should be rooted"
    echo "This is false warning and you can answer either yes or no."
}



if [[ "$ACTION" == HELP ]]; then
    echo "HELP" 
    print_usage
else if [[ "$ACTION" == FULL ]]; then
    detect_device
    check_build_for_su_update
    echo "FULL install"
    create_temp_dir
    download_su_package
    download_app_update
    download_recovery
    
    install_ubuntu_installer
    install_su
    
    delete_temp_dir
else if [[ "$ACTION" == INSTALL_SU ]]; then
    detect_device
    check_build_for_su_update
    echo "INSTALL_SU"
    create_temp_dir
    download_su_package
    download_recovery
    
    install_su
    
    delete_temp_dir
else if [[ "$ACTION" == UPDATE ]]; then
    detect_device
    create_temp_dir
    echo "UPDATE install"
    download_app_update
    download_recovery
    
    install_ubuntu_installer
    
    delete_temp_dir
else 
    echo "Sorry buddy!! better luck next time"
    print_ask_help
fi
fi
fi
fi
