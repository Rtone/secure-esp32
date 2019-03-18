#!/bin/bash

cat << EOF

ESP32-WROOM-DevKIT-V1

EOF


ESP_TOOLCHAIN=$false 
ESP_TOOLCHAIN_URL="https://dl.espressif.com/dl/xtensa-esp32-elf-linux64-1.22.0-80-g6c4433a-5.2.0.tar.gz"
ESP_TOOLCHAIN_VERSION="xtensa-esp32-elf-linux64-1.22.0-80-g6c4433a-5.2.0.tar.gz"


set_up_env()
{
    ENV_BASEDIR=$(pwd)

    if [[ $(uname) = "Linux" ]];
    then 

        # Install required Debian based distros packages to compile with ESP-IDF
        sudo apt-get update && sudo apt-get install -y gcc git wget make libncurses-dev flex bison gperf python python-pip python-setuptools python-serial python-cryptography python-future python-pyparsing
        retval_nux_packages=$?


cat << EOF

Set up toolchain ...
EOF
        mkdir -p $ENV_BASEDIR/toolchain
        curl -OJL $ESP_TOOLCHAIN_URL
        echo tar: extracting $ESP_TOOLCHAIN_VERSION
        tar xvzf $ESP_TOOLCHAIN_VERSION -C $ENV_BASEDIR/toolchain/
        retval_toolchain=$?
        rm $ESP_TOOLCHAIN_VERSION

cat << EOF

Set up ESP-IDF ...
EOF

        # Get ESP-IDF git Depo
        echo "[+] Downloading esp-idf ..."  
        git clone --recursive https://github.com/espressif/esp-idf.git $ENV_BASEDIR/esp-idf
        retval_esp_idf=$?

cat << EOF

Set up IDF_PATH Env variable ...
EOF
        # Setup IDF_PATH for login shells
        echo "export IDF_PATH=~$ENV_BASEDIR/esp-idf" >> ~/.profile
        echo "export PATH=\"$ENV_BASEDIR/toolchain/xtensa-esp32-elf/bin:\$PATH\"" >> ~/.profile        
        source ~/.profile
        retval1_idf_path=$?

        # Setup IDF_PATH for non-login shells
        echo "export IDF_PATH=~$ENV_BASEDIR/esp-idf" >> ~/.bashrc
        echo "export PATH=\"$ENV_BASEDIR/toolchain/xtensa-esp32-elf/bin:\$PATH\"" >> ~/.bashrc
        source ~/.bashrc 
        retval2_idf_path=$?

cat << EOF

Install Python requirement ...
EOF
        python -m pip install --user -r "$IDF_PATH/requirements.txt"
        retval_py_req=$?

    else
        >&2 echo "OS Unknown: $(uname)"
        exit 1
    fi

# Status of development environment set up
if [[ $retval_nux_packages -eq 0 ]]; then echo "[+] Packages installed successfully"; else echo "[-] Failed to install packages"; fi
if [[ $retval_toolchain -eq 0 ]]; then echo "[+] Toolchain binaries downloaded successfully"; else echo "[-] Failed to download toolchain binaries"; fi
if [[ $retval_esp_idf -eq 0 ]]; then echo "[+] ESP-IDF repository cloned successfully"; else echo "[-] Failed to clone ESP-IDF repository"; fi
if [[ $retval1_idf_path -eq 0 ]]; then echo "[+] IDF-PATH in \"profile\" edited successfully"; else echo "[-] Failed to edit IDF-PATH in \"profile\""; fi
if [[ $retval2_idf_path -eq 0 ]]; then echo "[+] IDF-PATH in \"bashrc\" edited successfully"; else echo "[-] Failed to edit IDF-PATH in \"bashrc\""; fi
if [[ $retval_py_req -eq 0 ]]; then echo "[+] Python requirements for ESP-IDF installed successfully"; else echo "[-] Failed to install python requirements for ESP-IDF"; fi

}

increase_entropy()
{
    if [[ $(uname) = "Linux" ]];
    then
        retValue=$(cat /proc/sys/kernel/random/entropy_avail)
        is_rngd_running=$(ps -ef | grep rngd | grep -v grep)
        ret_rngd=$?

        if [[ $retValue -lt 3000 &&  $ret_rngd -ne 0 ]];
        then 
            echo "[+] Your entropy level is $retValue"
            echo "[+] Entopy level must be increased for a robust random key"
            echo "[+] Installing RNG-tools package ..."
            sudo apt-get install -y rng-tools
            rng_file=$(<"/etc/default/rng-tools")
            if [[ $rng_file == *HRNGDEVICE=/dev/urandom* ]];
            then   
                echo "[+] Uncomment HRNGDEVICE value"
                sudo sh -c "sed -i '/HRNGDEVICE=\/dev\/urandom/s/^#//g' /etc/default/rng-tools"
            else
                echo "[+] Set HRNGDEVICE value"
                sudo sh -c "echo 'HRNGDEVICE=/dev/urandom' >> /etc/default/rng-tools"
            fi
            sudo systemctl start rng-tools.service
        elif [[ $retValue -gt 3000 && $ret_rngd -ne 0 ]]
        then
            echo "[+] Your entropy level is $retValue"
            while true; do
                read -r -p "Do you wish to increase more and more your entropy? (Y/N) " yn
                case $yn in
                    [Yy]* ) 
                        sudo apt-get install -y rng-tools
                        rng_file=$(<"/etc/default/rng-tools")
                        if [[ $rng_file == *HRNGDEVICE=/dev/urandom* ]];
                        then   
                            echo "[+] Uncomment HRNGDEVICE value or already uncommented"
                            sudo sh -c "sed -i '/HRNGDEVICE=\/dev\/urandom/s/^#//g' /etc/default/rng-tools"
                        else
                            echo "[+] Set HRNGDEVICE value"
                            sudo sh -c "echo 'HRNGDEVICE=/dev/urandom' >> /etc/default/rng-tools"
                        fi
                        sudo systemctl start rng-tools.service
                        return 0
                        ;;

                    [Nn]* )
                        echo "[+] the answer is No ..." 
                        return 1
                        ;;

                    * ) 
                        echo "[+] Please answer yes or no."
                        ;;
                esac
            done
        else 
            echo "[+] RNG-tools is running ..."            
        fi
    else
        >&2 echo "OS Unknown: $(uname)"
        exit 1
    fi 
}

gen_encrypt_key()
{
    ESP_TOOL_PYTHON=$IDF_PATH/components/esptool_py/esptool

    case "$1" in 
        "/dev/ttyUSB0"*)
            flash_enc=$(python $ESP_TOOL_PYTHON/espefuse.py --port $1 summary | awk  '$1 ~/FLASH_CRYPT_CNT/' | cut -d"=" -f2 | awk '{print $1}')

            if [[ $flash_enc -eq 0 ]];
            then
                echo "[+] Flash Encryption is disabled, you can generate Encrypttion Key and burn it in eFUSE BLK1 block"
                is_rngd_running=$(ps -ef | grep rngd | grep -v grep)
                if [[ $?  -eq "0" ]];
                then                
                    echo "[+] RNG-tools is running ..."
                else
                    echo "[+] RNG-tools is not running"
                    increase_entropy
                    ret_choice=$?
                    
                    if [[ $ret_choice -eq 0 ]];
                    then
                        echo "[+] Please wait 30 sec for \"increase_entropy\" to take place ..."
                        sleep 30
                    fi
                fi

                python $ESP_TOOL_PYTHON/espsecure.py generate_flash_encryption_key "$2"
                ret_gen_key=$?
                size=$(stat --printf="%s" "$2")
                if [[ $ret_gen_key -eq 0 && size -eq 32 ]];
                then
                    echo "[+] Generation Flash Encryption Key succeed !"
                    echo "[+] Stop RNG-tools service please wait ..."
                    sudo systemctl stop rng-tools.service
                else
                    echo "[+] Generation Flash Encryption Key Failed !"
                fi
            else 
                echo "[+] Flash Encryption is enabled"
                echo "[+] Which means a Flash Encryption Key is already burned"
            fi

            ;;

        *) 
            echo "[Error] could not open port "$1""
            echo "Warning: please make sure to write the right Serial Port (Default /dev/ttyUSB0)"
            ;;
    esac
}

gen_signing_key()
{
    ESP_TOOL_PYTHON=$IDF_PATH/components/esptool_py/esptool

    case "$1" in 
        "/dev/tty"*)
            sec_boot=$(python $ESP_TOOL_PYTHON/espefuse.py --port $1 summary | awk  '$1 ~/ABS_DONE_0/' | cut -d"=" -f2 | awk '{print $1}')

            if [[ $sec_boot -eq 0 ]]; 
            then
                echo "[+] Secure Boot is disabled, you can generate Signing Key and burn it in eFUSE BLK2 block"
                is_rngd_running=$(ps -ef | grep rngd | grep -v grep)
                if [[ $?  -eq "0" ]];
                then
                    echo "[+] RNG-tools is running ..."
                else
                    echo "[+] RNG-tools is not running"
                    increase_entropy
                    ret_choice=$?
                    
                    if [[ $ret_choice -eq 0 ]];
                    then
                        echo "[+] Please wait 30 sec for \"increase_entropy\" to take place ..."
                        sleep 30
                    fi
                fi

                python $ESP_TOOL_PYTHON/espsecure.py generate_signing_key "$2"
                ret_gen_key=$?
                echo $ret_gen_key

                check_sign_key=$(<$2)

                if [[ $ret_gen_key -eq 0 && $check_sign_key == -----BEGIN* ]];
                then
                    echo "[+] Generation Secure Boot Signing Private Key succeed !"
                    echo "[+] Stop RNG-tools service please wait ..."
                    sudo systemctl stop rng-tools.service
                else
                    echo "[+] Generation Secure Boot Signing Private Key Failed !"
                fi
            else 
                echo "[+] Secure Boot is enabled."
                echo "[+] Which means a Secure Boot Signing Key is already burned"
            fi

            ;;
        
        *) 
            echo "[Error] could not open port "$1""
            echo "Warning: please make sure to write the right Serial Port (Default /dev/ttyUSB0)"
            ;;
    esac
}

help()
{
    __usage="
    Usage:  source $(basename "$0") [OPTIONS]

    Options:
    --set-env               Set up development environment 
    --increase-entropy      Increase the entropy level for better random numbers source 
    --encrypt-key           Generate Flash Encryption Key
        [--port <SERIAL PORT> <Enc Key file name>]
    --signing-key           Generate Flash Encryption Key     
        [--port <SERIAL PORT> <Sig Key file name>]   
    --help                  Display this help and exit

    "
    echo "$__usage"
}

test_shell()
{
    echo "ok"
}

main()
{
    case "$1" in
        "--set-env")
            set_up_env
            ;;
    
        "--increase-entropy")
            increase_entropy
            ;;

        "--encrypt-key")
            case "$2" in 
                "--port")
                    gen_encrypt_key "$3" "$4"
                    echo "$4"
                    ;;

                *)
                    echo "Error: argument operation." 
                    echo "Check \"help\" list"
                    help
                    ;;
            esac
            ;;
        
        "--signing-key")
            case "$2" in 
                "--port")
                    gen_signing_key "$3" "$4"
                    ;;

                *)
                    echo "[Error]: argument operation"
                    echo "Warning: check \"help\" list"
                    help
                    ;;
            esac
            ;;
        
        "--help")
            help
            ;;

        "--test")
            test_shell
            ;;
        
        *)
            help
            ;;

    esac  
}

main "$@" 
