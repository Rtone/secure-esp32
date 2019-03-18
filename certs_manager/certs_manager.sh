#!/bin/bash

cat << EOF

CERTIFICATE MANAGEMENT TOOL

EOF

__rootCA_subject="
##########################################
# countryName           : [N] => FR
# stateOrProvinceName   :[ST] => Rhone
# localityName          : [L] => Lyon 
# organizationName      :[ON] => Rtone
# organizationalUnitName:[OU] => CERT
# commonName            :[CN] => root-CA
##########################################
"

__signingCA_subject="
##########################################
# countryName           : [N] => FR
# stateOrProvinceName   :[ST] => Rhone
# localityName          : [L] => Lyon 
# organizationName      :[ON] => Rtone
# organizationalUnitName:[OU] => CERT
# commonName            :[CN] => intermediate-CA
##########################################
"

__serverCrt_subject="
##########################################
# countryName           : [N] => FR
# stateOrProvinceName   :[ST] => Rhone
# localityName          : [L] => Lyon 
# organizationName      :[ON] => Rtone
# organizationalUnitName:[OU] => CERT
# commonName            :[CN] => <IP ADDRESS>
##########################################
"

__guestCrt_subject="
##########################################
# countryName           : [N] => FR
# stateOrProvinceName   :[ST] => Rhone
# localityName          : [L] => Lyon 
# organizationName      :[ON] => Rtone
# organizationalUnitName:[OU] => CERT
# commonName            :[CN] => guest
##########################################
"


help()
{
    me=${0##*/}
    echo $me
    __usage="
    Usage:  source $me [OPTIONS]

    Options:
    --root-ca 
        [--req | --ca]          Creates and processes Root certificate
    --intermediate-ca  
        [--req | --ca]          Creates and processes intermediate certificate
    --subinter-ca  
        [--req | --ca]          Creates and processes sub intermediate certificate
    --server 
        [--req | --ca]          Creates and processes server's certificate, only to establish HTTPS connections
    --guest
        [--req | --ca]          Creates and processes guests certificate, to ask for an imei certificate
    --gen-from-file
    "
    echo "$__usage"

}

BASEDIR=$(pwd)

OPENSSL_CONFIG="$BASEDIR/config/openssl.conf"

OPENSSL_ROOT_CONFIG="$BASEDIR/config/root-ca.conf"
OPENSSL_INTERMEDIATE_CONFIG="$BASEDIR/config/intermediate-ca.conf"
OPENSSL_SUBINTER_CONFIG="$BASEDIR/config/subinter-ca.conf"
OPENSSL_SERVER_CONFIG="$BASEDIR/config/server.conf"
OPENSSL_GUEST_CONFIG="$BASEDIR/config/guest.conf"

VAR_CONFIGFILE="$BASEDIR/config/pki.conf"


# A tester le set up Env.  
set_up_env()
{
    # Install the latest version of OpenSSL 
    sudo apt-get update
    sudo apt-get -y install build-essential checkinstall zlib1g-dev libtemplate-perl
    sudo apt-get -y remove openssl
    sudo apt-get -y install gcc
    sudo apt-get -q update && apt-get -qy install wget make
    wget https://www.openssl.org/source/openssl-1.1.1a.tar.gz 
    tar -xzvf openssl-1.1.1a.tar.gz 
    cd openssl-1.1.1a 
    $BASEDIR/config 
    make install 
    ln -sf /usr/local/ssl/bin/openssl 'which openssl'

    export LD_LIBRARY_PATH="/usr/local/lib"

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

#######################################################################
##
##   Root CA
## 
#######################################################################

root_req()
{
    echo "$__rootCA_subject"
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

    openssl req \
    -new -config $OPENSSL_ROOT_CONFIG \
    -out $name_root_folder/csr/"$name_root_crt".csr \
    -keyout $name_root_folder/private/"$name_root_crt".key

    is_rngd_running=$(ps -ef | grep rngd | grep -v grep)
    if [[ $?  -eq "0" ]];
    then
        while true; do
            read -p "Do you wish stop rng-tools service?" yn
            case $yn in
                [Yy]* ) 
                    sudo systemctl stop rng-tools.service
                    break
                    ;;

                [Nn]* ) 
                    break
                    ;;
                * ) 
                    echo "Please answer with yes or no"
                    ;;
            esac
        done
    fi
}

root_selfsign()
{
    openssl ca -batch \
    -selfsign -config $OPENSSL_ROOT_CONFIG \
    -in $name_root_folder/csr/"$name_root_crt".csr \
    -out $name_root_folder/"$name_root_crt".crt \
    -extensions root_ca_ext
}


set_rootCA_env_dev()
{
    [[ ! -d $name_root_folder/private ]] && mkdir -p $name_root_folder/private || echo "Folder already exists"
    [[ ! -d $name_root_folder/csr ]] && mkdir -p $name_root_folder/csr || echo "Folder already exists"
    [[ ! -d $name_root_folder/db ]] && mkdir -p $name_root_folder/db || echo "Folder already exists"
    [[ ! -d $name_root_folder/certs_archive ]] && mkdir -p $name_root_folder/certs_archive || echo "Folder already exists"

    if [[ ! -f "$BASEDIR/root_ca/db/serial" ]];
    then
        touch $name_root_folder/db/serial 
        echo "1000" > $name_root_folder/db/serial
    else
        echo "[ + ] Don't do anything..."
    fi

    if [[ ! -f "$BASEDIR/root_ca/db/index" ]]
    then
        touch $name_root_folder/db/index
    else
        echo "[ + ] Don't do anything..."
    fi

    if [[ ! -f "$BASEDIR/$name_root_folder/db/index.attr" ]]
    then
        touch $name_root_folder/db/index.attr
    else
        echo "[ + ] Don't do anything..."
    fi
    
    if [[ ! -f "$BASEDIR/root_ca/db/crlnumber" ]]
    then
        touch $name_root_folder/db/crlnumber
    else
        echo "[ + ] Don't do anything..."
    fi
}

set_rootCA_env_var()
{
    export DIR="$BASEDIR/$name_root_folder"
    export CA_NAME="$name_root_crt"
    export X509EXT="intermediate_ca_ext"
    export countryName="FR"
    export stateOrProvinceName="Rhone"   
    export localityName="Lyon"          
    export organizationName="Rtone"      
    export organizationalUnitName="CERT"
    export commonName="root-CA"

}

root_CA()
{
    set_rootCA_env_dev
    set_rootCA_env_var

    echo "root-ca"
    case "$1" in 
        
        "--req" )
            root_req
            ;;

        "--ca" )
            root_selfsign
            ;;

    esac
}

#######################################################################
##
##   END of Root CA
## 
#######################################################################

#######################################################################
##
##  Intermediate CA
## 
#######################################################################
intermediate_req()
{

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

    echo "$__signingCA_subject"
    openssl req  \
    -config $OPENSSL_INTERMEDIATE_CONFIG \
    -newkey rsa:2048 -nodes \
    -out $name_intermediate_folder/csr/"$name_intermediate_crt".csr \
    -keyout $name_intermediate_folder/private/"$name_intermediate_crt".key \
    -subj $subject_intermediate

    is_rngd_running=$(ps -ef | grep rngd | grep -v grep)
    if [[ $?  -eq "0" ]];
    then
        while true; do
            read -p "Do you wish stop rng-tools service?" yn
            case $yn in
                [Yy]* ) 
                    sudo systemctl stop rng-tools.service
                    break
                    ;;

                [Nn]* ) 
                    break
                    ;;
                * ) 
                    echo "Please answer with yes or no"
                    ;;
            esac
        done
    fi
}

sign_intermediate_ca()
{
    openssl ca -batch \
    -config $OPENSSL_ROOT_CONFIG \
    -in $name_intermediate_folder/csr/"$name_intermediate_crt".csr \
    -out $name_intermediate_folder/"$name_intermediate_crt".crt \
    -days 365 -extensions intermediate_ca_ext 
}

set_intermediateCA_env_dev()
{
    [[ ! -d $name_intermediate_folder/private ]] && mkdir -p $name_intermediate_folder/private || echo "Folder already exists"
    [[ ! -d $name_intermediate_folder/csr ]] && mkdir -p $name_intermediate_folder/csr || echo "Folder already exists"
    [[ ! -d $name_intermediate_folder/db ]] && mkdir -p $name_intermediate_folder/db || echo "Folder already exists"
    [[ ! -d $name_intermediate_folder/certs_archive ]] && mkdir -p $name_intermediate_folder/certs_archive || echo "Folder already exists"

    if [[ ! -f "$BASEDIR/$name_intermediate_folder/db/serial" ]];
    then
        touch $name_intermediate_folder/db/serial 
        echo "2000" > $name_intermediate_folder/db/serial
    else
        echo "[ + ] Don't do anything..."
    fi

    if [[ ! -f "$BASEDIR/$name_intermediate_folder/db/index" ]]
    then
        touch $name_intermediate_folder/db/index
    else
        echo "[ + ] Don't do anything..."
    fi

    if [[ ! -f "$BASEDIR/$name_intermediate_folder/db/index.attr" ]]
    then
        touch $name_intermediate_folder/db/index.attr
    else
        echo "[ + ] Don't do anything..."
    fi

    if [[ ! -f "$BASEDIR/$name_intermediate_folder/db/crlnumber" ]]
    then
        touch $name_intermediate_folder/db/crlnumber
    else
        echo "[ + ] Don't do anything..."
    fi
}

set_intermediateCA_env_var()
{
    export DIR="$BASEDIR/$name_intermediate_folder"
    export CA_NAME="$name_intermediate_crt"
    export X509EXT="sub_intermediate_ca_ext"
    export INTERPATHLEN="$intermediate_path_len"
    export countryName="FR"
    export stateOrProvinceName="Rhone"   
    export localityName="Lyon"          
    export organizationName="Rtone"      
    export organizationalUnitName="CERT"
    export commonName="intermediate-CA"
}

intermediate_CA()
{


    echo "intermediate-ca"
    case "$1" in 
        
        "--req" )
            set_intermediateCA_env_var
            set_intermediateCA_env_dev
            intermediate_req
            ;;

        "--ca" )
            PS3='Please choice the Cert to sign with : '
            options=("root-ca" "Option 2" "Option 3" "Quit")
            select opt in "${options[@]}"
            do
                case $opt in
                    "root-ca")
                        echo "you chose to sign with $opt"
                        set_rootCA_env_var
                        sign_intermediate_ca 
                        break
                        ;;

                    "Quit")
                        break
                        ;;

                    *) 
                    echo "invalid option $REPLY"
                    ;;

                esac
            done
            
            ;;

    esac
}

#######################################################################
##
##   END of Intermediate CA
## 
#######################################################################

#######################################################################
##
##   SUB-Intermediate CA
## 
#######################################################################

sub_intermediate_req()
{

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

    echo "$__signingCA_subject"
    echo "$subject_subinter"
    
    openssl req  \
    -config $OPENSSL_SUBINTER_CONFIG \
    -newkey rsa:2048 -nodes \
    -out $name_subinter_folder/csr/$name_subinter_crt.csr \
    -keyout $name_subinter_folder/private/$name_subinter_crt.key \
    -subj $subject_subinter

    is_rngd_running=$(ps -ef | grep rngd | grep -v grep)
    if [[ $?  -eq "0" ]];
    then
        while true; do
            read -p "Do you wish stop rng-tools service?" yn
            case $yn in
                [Yy]* ) 
                    sudo systemctl stop rng-tools.service
                    break
                    ;;

                [Nn]* ) 
                    break
                    ;;
                * ) 
                    echo "Please answer with yes or no"
                    ;;
            esac
        done
    fi
}

sub_sign_intermediate_ca()
{
    openssl ca -batch \
    -config $1 \
    -in $name_subinter_folder/csr/$name_subinter_crt.csr \
    -out $name_subinter_folder/$name_subinter_crt.crt \
    -days 365 -extensions sub_intermediate_ca_ext 
}

set_sub_intermediateCA_env_dev()
{
    [[ ! -d $name_subinter_folder/private ]] && mkdir -p $name_subinter_folder/private || echo "Folder already exists"
    [[ ! -d $name_subinter_folder/csr ]] && mkdir -p $name_subinter_folder/csr || echo "Folder already exists"
    [[ ! -d $name_subinter_folder/db ]] && mkdir -p $name_subinter_folder/db || echo "Folder already exists"
    [[ ! -d $name_subinter_folder/certs_archive ]] && mkdir -p $name_subinter_folder/certs_archive || echo "Folder already exists"

    if [[ ! -f "$BASEDIR/$name_subinter_folder/db/serial" ]];
    then
        touch $name_subinter_folder/db/serial 
        echo "3000" > $name_subinter_folder/db/serial
    else
        echo "[ + ] Don't do anything..."
    fi

    if [[ ! -f "$BASEDIR/$name_subinter_folder/db/index" ]]
    then
        touch $name_subinter_folder/db/index
    else
        echo "[ + ] Don't do anything..."
    fi

    if [[ ! -f "$BASEDIR/$name_subinter_folder/db/index.attr" ]]
    then
        touch $name_subinter_folder/db/index.attr
    else
        echo "[ + ] Don't do anything..."
    fi

    if [[ ! -f "$BASEDIR/$name_subinter_folder/db/crlnumber" ]]
    then
        touch $name_subinter_folder/db/crlnumber
    else
        echo "[ + ] Don't do anything..."
    fi
}

set_sub_intermediateCA_env_var()
{
    export DIR="$BASEDIR/$name_subinter_folder"
    export CA_NAME="$name_subinter_crt"
    export X509EXT="server_ext"
    export SUBINTERPATHLEN="$subinter_path_len"
    export countryName="FR"
    export stateOrProvinceName="Rhone"   
    export localityName="Lyon"          
    export organizationName="Rtone"      
    export organizationalUnitName="CERT"
    export commonName="sub-inter-CA"
}

sub_intermediate_CA()
{

    echo "sub_intermediate-ca"
    case "$1" in 
        
        "--req" )
            set_sub_intermediateCA_env_var
            set_sub_intermediateCA_env_dev
            sub_intermediate_req
            ;;

        "--ca" )
            PS3='Please choice the Cert to sign with : '
            options=("root-ca" "intermediate-ca" "Quit")
            select opt in "${options[@]}"
            do
                case $opt in
                    "root-ca")
                        echo "you chose to sign with $opt"
                        set_rootCA_env_var
                        sub_sign_intermediate_ca $OPENSSL_ROOT_CONFIG
                        break
                        ;;
                    "intermediate-ca")
                        echo "you chose to sign with $opt"
                        set_intermediateCA_env_var
                        sub_sign_intermediate_ca $OPENSSL_INTERMEDIATE_CONFIG
                        break
                        ;;

                    "Quit")
                        break
                        ;;
                    *) echo "invalid option $REPLY";;
                esac
            done
            
            ;;

    esac
}

#######################################################################
##
##   END of SUB-Intermediate CA
## 
#######################################################################

#######################################################################
##
##   Server CRT
## 
#######################################################################

server_req()
{

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

    echo "$__serverCrt_subject"
    openssl req \
    -config $OPENSSL_SERVER_CONFIG \
    -newkey rsa:2048 -nodes \
    -out $name_sever_folder/csr/$name_server_crt.csr \
    -keyout $name_sever_folder/private/$name_server_crt.key \
    -subj $subject_server

    is_rngd_running=$(ps -ef | grep rngd | grep -v grep)
    if [[ $?  -eq "0" ]];
    then
        while true; do
            read -p "Do you wish stop rng-tools service?" yn
            case $yn in
                [Yy]* ) 
                    sudo systemctl stop rng-tools.service
                    break
                    ;;

                [Nn]* ) 
                    break
                    ;;
                * ) 
                    echo "Please answer with yes or no"
                    ;;
            esac
        done
    fi
}

server_ca()
{

    # Sign with subint, so we should put "-config $OPENSSL_SUBINTER_CONFIG "
    
    openssl ca -batch \
    -config $1 \
    -in $name_sever_folder/csr/$name_server_crt.csr \
    -out $name_sever_folder/$name_server_crt.crt -days 365 \
    -extensions server_ext

}


set_server_env_dev()
{
    [[ ! -d $name_sever_folder/private ]] && mkdir -p $name_sever_folder/private || echo "Folder already exists"
    [[ ! -d $name_sever_folder/csr ]] && mkdir -p $name_sever_folder/csr || echo "Folder already exists"
    [[ ! -d $name_sever_folder/db ]] && mkdir -p $name_sever_folder/db || echo "Folder already exists"
    [[ ! -d $name_sever_folder/certs_archive ]] && mkdir -p $name_sever_folder/certs_archive || echo "Folder already exists"
}

set_server_env_var()
{
    export DIR="$BASEDIR/$name_sever_folder"
    export CA_NAME="$name_server_crt"
    export countryName="FR"
    export stateOrProvinceName="Rhone"   
    export localityName="Lyon"          
    export organizationName="Rtone"      
    export organizationalUnitName="CERT"
    export commonName="37.59.96.8"
}

server_Crt()
{

    echo "sub_intermediate-ca"
    case "$1" in 
        
        "--req" )
            set_server_env_var
            set_server_env_dev
            server_req
            ;;

        "--ca" )
            PS3='Please choice the Cert to sign with : '
            options=("root-ca" "intermediate-ca" "subinter-ca" "Quit")
            select opt in "${options[@]}"
            do
                case $opt in
                    "root-ca")
                        echo "you chose to sign with $opt"
                        set_rootCA_env_var
                        server_ca $OPENSSL_ROOT_CONFIG
                        break
                        ;;
                    
                    "intermediate-ca")
                        echo "you chose to sign with $opt"
                        set_intermediateCA_env_var
                        server_ca $OPENSSL_INTERMEDIATE_CONFIG
                        break
                        ;;

                    "subinter-ca")
                        echo "you chose to sign with $opt"
                        set_sub_intermediateCA_env_var
                        server_ca $OPENSSL_SUBINTER_CONFIG
                        break
                        ;;

                    "Quit")
                        break
                        ;;

                    *) 
                    echo "invalid option $REPLY, retry"
                    ;;
                esac
            done
            
            ;;

    esac

}

#######################################################################
##
##   END of Server CRT
## 
#######################################################################

#######################################################################
##
##   Guest CRT
## 
#######################################################################
guest_req()
{
    
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

    echo "$__guestCrt_subject"
    openssl req \
    -config $OPENSSL_GUEST_CONFIG \
    -newkey rsa:2048 -nodes \
    -out $name_guest_folder/csr/$name_guest_crt.csr \
    -keyout $name_guest_folder/private/$name_guest_crt.key
    -subj $subject_guest

    is_rngd_running=$(ps -ef | grep rngd | grep -v grep)
    if [[ $?  -eq "0" ]];
    then
        while true; do
            read -p "Do you wish stop rng-tools service?" yn
            case $yn in
                [Yy]* ) 
                    sudo systemctl stop rng-tools.service
                    break
                    ;;

                [Nn]* ) 
                    break
                    ;;
                * ) 
                    echo "Please answer with yes or no"
                    ;;
            esac
        done
    fi
}

guest_ca()
{
    
    openssl ca -batch \
    -config $1 \
    -in $name_guest_folder/csr/$name_guest_crt.csr \
    -out $name_guest_folder/$name_guest_crt.crt \
    -extensions guest_ext

}

set_guest_env_dev()
{
    [[ ! -d $name_guest_folder/private ]] && mkdir -p $name_guest_folder/private || echo "Folder already exists"
    [[ ! -d $name_guest_folder/csr ]] && mkdir -p $name_guest_folder/csr || echo "Folder already exists"
    [[ ! -d $name_guest_folder/db ]] && mkdir -p $name_guest_folder/db || echo "Folder already exists"
    [[ ! -d $name_guest_folder/certs_archive ]] && mkdir -p $name_guest_folder/certs_archive || echo "Folder already exists"
}

set_guest_env_var()
{
    export DIR="$BASEDIR/$name_guest_folder"
    export CA_NAME="$name_guest_crt"
    export countryName="FR"
    export stateOrProvinceName="Rhone"   
    export localityName="Lyon"          
    export organizationName="Rtone"      
    export organizationalUnitName="CERT"
    export commonName="guest"
}
guest_Crt()
{

    echo "guest"
    case "$1" in 
        
        "--req" )
            set_guest_env_var
            set_guest_env_dev
            guest_req
            ;;

        "--ca" )
            PS3='Please choice the Cert to sign with : '
            options=("root-ca" "intermediate-ca" "subinter-ca" "Quit")
            select opt in "${options[@]}"
            do
                case $opt in
                    "root-ca")
                        echo "you chose to sign with $opt"
                        set_rootCA_env_var
                        guest_ca $OPENSSL_ROOT_CONFIG
                        break
                        ;;
                    
                    "intermediate-ca")
                        echo "you chose to sign with $opt"
                        set_intermediateCA_env_var
                        guest_ca $OPENSSL_INTERMEDIATE_CONFIG
                        break
                        ;;

                    "subinter-ca")
                        echo "you chose to sign with $opt"
                        set_sub_intermediateCA_env_var
                        guest_ca $OPENSSL_SUBINTER_CONFIG
                        break
                        ;;

                    "Quit")
                        break
                        ;;

                    *) 
                    echo "invalid option $REPLY, retry"
                    ;;
                esac
            done
            
            ;;

    esac
}

#######################################################################
##
##   Guest CRT
## 
#######################################################################


gen_form_fileconf()
{
    root_CA "--req"
    root_CA "--ca"
    intermediate_CA "--req"
    intermediate_CA "--ca"
    sub_intermediate_CA "--req"
    sub_intermediate_CA "--ca"
    server_Crt "--req"
    server_Crt "--ca"
    
}

#######################################################################
##
##  Verify Server.crt (signed by Subinter-ca) 
##  et Guest.crt(signed by Intermediate-ca) ==> TODO 
##
##  $ openssl verify 
##        -CAfile root_ca/root-ca.crt \
##        -untrusted intermediate_ca/intermediate-ca.crt \
##        -untrusted sub_inter_ca/sub-inter-ca.crt \
##        server/server.crt
## 
##  $ openssl verify 
##        -CAfile root_ca/root-ca.crt \
##        -untrusted intermediate_ca/intermediate-ca.crt \
##        guest/guest.crt
## 
#######################################################################

main() 
{
    if [[ $(uname) = "Linux" ]];
    then 

        source "$VAR_CONFIGFILE"

        case "$1" in 
            "--root-ca")
                root_CA "$2"
                ;;

            "--intermediate-ca")
                intermediate_CA "$2"
                ;;
            
            "--subinter-ca")
                sub_intermediate_CA "$2"
                ;;

            "--server")
                server_Crt "$2" 
                ;;

            "--guest")
                guest_Crt "$2"
                ;;

            "--gen-from-file")
                gen_form_fileconf
                ;;

            "--help")
                help
                ;;        

            *)
                help
                ;;
        esac
    else
        >&2 echo "OS Unknown: $(uname)"
        exit 1
    fi 
}

main "$@"