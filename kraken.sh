#!/bin/bash

deploydir="$(cd "$(dirname "$0")" && pwd)"
#if [ "${PWD##*/}" == "deploy" ]; then
#	cd ..
#fi

if [ "$2" == "!" ]; then
	ReleaseTheKraken=true;
else
	ReleaseTheKraken=false;
fi



if [ ! -d ${deploydir}/working ]; then
	mkdir ${deploydir}/working
fi

if [ ! -d ${deploydir}/conf ]; then
	mkdir ${deploydir}/conf
fi

if [ ! -d ${deploydir}/certs ]; then
	mkdir ${deploydir}/certs
    echo
    echo "Put two-factor auth certificates in the 'certs' directory."
    echo
fi

homedir=${deploydir}/working
#homedir="$(cd "$(dirname "$0")" && pwd)"


if [ "$(uname -s)" == "Cygwin" ]; then
	os="cygwin"
elif [ "$(uname -s)" == "Darwin" ]; then
	os="osx"
else
	os="nix"
fi

source ${deploydir}/bin/conf.sh
source ${deploydir}/bin/depends.sh
source ${deploydir}/bin/color.sh
source ${deploydir}/bin/scp.sh
source ${deploydir}/bin/minify.sh
source ${deploydir}/bin/func.sh
source ${deploydir}/bin/dwdav.sh

if [[ ! -e ${deploydir}/conf/cartridges.conf || ! -s ${deploydir}/conf/cartridges.conf ]]; then
    touch ${deploydir}/conf/cartridges.conf
    echo
    echo "You must list all cartridges to deploy in the cartridges.conf file."
    echo
    exit 1 
fi

IFS=$'\r\n' read -d '' -r -a cartridges < ${deploydir}/conf/cartridges.conf

printf "\033c"
kraken
printf  "\r\nDemand${txtgrn}ware${txtrst} Build Script\r\n"
echo

case "$1" in
        deploy)
			scp_configure
			scp_verify_login
			scp_checkout			
			dw_configure
            inc_build_number
			minify			
			zip_cartridges
			dw_upload_build
			scp_tag
			echo "Cartridges uploaded to $dwbuild."
            ;;                     
        build)			
			scp_configure
			scp_verify_login
			scp_checkout			
            inc_build_number
			minify
			zip_cartridges	
			scp_tag
			echo
			echo "Cartridge archive created."
            ;;      
        gzip)
            inc_build_number
            minify
            zip_cartridges
            echo
            echo "Cartridges gzip'd."
            ;;
        update)
			scp_configure
            scp_verify_login
			scp_checkout            
			echo "Updated cartridges."
            ;;
        cert)
			dw_configure
			echo
			echo "Client certificate created."
            ;;        
		upload)
			dw_configure
			dw_upload_build
			echo
			echo "Cartridges uploaded to $dwbuild."			
			;;
		test)
			make_clientcert
			;;
        *)
            echo $"Usage: $0 {deploy|build|update|cert|upload}"
            exit 1
 
esac

exit 1


