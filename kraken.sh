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

if [[ "$1" != "status" && "$1" != "version" ]]; then	
	printf "\033c"
	kraken
	printf  "\r\nDemand${txtgrn}ware${txtrst} Build Script\r\n"
	echo

	status=$(read_status)

	if [[ "$status" != "" && "$1" != "clean" ]]; then
		echo "Kraken is busy with another task, try again later."
		exit 1
	fi
fi

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
			write_status ""
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
			write_status ""
			echo
			echo "Cartridge archive created."
      		;;
    update)
			scp_configure
      		scp_verify_login
			scp_checkout
			write_status ""
			echo "Updated cartridges."
      		;;
	gzip)
			inc_build_number
			minify
			zip_cartridges
			write_status ""
			echo
			echo "Cartridges gzip'd."
			;;
    cert)
			dw_configure
			write_status ""
			echo
			echo "Client certificate created."
      		;;
	upload)
			dw_configure
			inc_build_number
			zip_cartridges
			dw_upload_build
			write_status ""
			echo
			echo "Cartridges uploaded to $dwbuild."
			;;
	clean)
			if [ -d ${deploydir}/working ]; then
				rm -rf ${deploydir}/working
			fi
			echo
			echo "Cleaned working directory."
			;;
	list)
			echo
			echo "Cartridges to be deployed:"
			cat ${deploydir}/conf/cartridges.conf
			echo
			;;
	add)
			if [ ${#2} -eq 0 ]; then
				echo "Usage: add [cartridge name]."
			else
				echo $2 >> ${deploydir}/conf/cartridges.conf
			fi
			echo
			echo "Appended ${2} cartridge."
			;;
	branch)
			write_conf "git" "branch" $2
			echo
			echo "Set branch to $2."			
			;;
	updatecurl)
		echo
		if [ "$os" == "nix" ]; then				
			echo "Updating cURL to 7.52.1..."
			sudo apt-get build-dep curl
			mkdir ~/curl
			cd ~/curl
			wget http://curl.haxx.se/download/curl-7.52.1.tar.bz2
			tar -xvjf curl-7.52.1.tar.bz2
			cd curl-7.52.1
			./configure
			make
			sudo make install
			sudo ldconfig
			echo "Done."
		else
			echo "cURL update procedure is only available for Linux environments."
		fi
		;;
	status)
		read_status
		exit 0
		;;
	version)
	 	lbn=$(read_conf "deploy" "lastBuild" "none")
		 echo $lbn		 
		 exit 0
		;;
	test)	
		v=$(read_status)
		echo $v
		;;
    *)
      echo $"Usage: $0 {deploy|build|update|cert|upload|clean|list|add}"
      exit 1

esac

exit 0
