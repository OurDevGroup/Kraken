requiresClientCertificate=false
certSubj="/C=US/ST=Some State/L=Some City/O=Some Company/OU=IT/CN=example.com"

dw_configure() {
	echo
    local serverProvided=false
    while ! $serverProvided; do
		if [ "${demandwareServer}" != "" ]; then
			read -p "Please enter the target Demandware server [$demandwareServer]: " newdwserver
		else
			read -p "Please enter the target Demandware server: " newdwserver
		fi
		
		demandwareServer=${newdwserver:-$demandwareServer}
        
		if [ "$demandwareServer" == "" ]; then
            echo "Server cannot be empty!"
        else
            serverProvided=true
            echo
        fi
    done
	
	if [ -f "${deploydir}/conf/${demandwareServer}.conf" ]; then
		source "${deploydir}/conf/${demandwareServer}.conf"
	else
		touch "${deploydir}/conf/${demandwareServer}.conf"
		echo "Generating new server configuration."
	fi
	
	local dwUserProvided=false
    while ! $dwUserProvided; do
		if [ "${demandwareUsername}" != "" ]; then
			read -p "Please enter the username for $demandwareServer [$demandwareUsername]: " newdwuser
		else
			read -p "Please enter the username for $demandwareServer : " newdwuser
		fi
		
		demandwareUsername=${newdwuser:-$demandwareUsername}
        
		if [ "$demandwareUsername" == "" ]; then
            echo "Username cannot be empty!"
        else
            dwUserProvided=true
            echo
        fi
    done

	local dwPassProvided=false
    if [ "$demandwarePassword" != "" ]; then
	   demandwarePassword=$(echo "$demandwarePassword" | openssl enc -aes-128-cbc -a -d -salt -pass "pass:$demandwareUsername")
    fi
    while ! $dwPassProvided; do
		if [ "$demandwarePassword" != "" ]; then
			read -p "Please enter the password for $demandwareServer [stored password]: " -s newdwpass
		else
			read -p "Please enter the password for $demandwareServer : " -s newdwpass
		fi
		
		demandwarePassword=${newdwpass:-$demandwarePassword}
        
		if [ "$demandwarePassword" == "" ]; then
            echo "Password cannot be empty!"
        else
            dwPassProvided=true
            echo
        fi
    done	
	
	echo
	if [[ $requiresClientCertificate == true ]]; then
		read -p "Does the server require a client certificate [Y/n]: " needsCert
		needsCert=${needsCert:-Y}
	else
		read -p "Does the server require a client certificate [y/N]: " needsCert
		needsCert=${needsCert:-N}
	fi
	
	if [[ "$needsCert" == "Y" ]]; then
		requiresClientCertificate=true
		echo
		read -p "Do you need to generate a client certificate [y/N]: " genCert
		genCert=${genCert:-N}
		if [ "${genCert}" == "Y" ]; then
			make_clientcert
		fi
	else
		requiresClientCertificate=false
	fi
	
	if [[ $requiresClientCertificate == true ]] && [[ $genCert == false ]]; then
		local certProvided=false
		echo
		while ! $certProvided; do
			if [ "${clientCertificate}" != "" ]; then
				read -p "Please enter the client certificate file [$clientCertificate]: " newcert
			else
				read -p "Please enter the client certificate file: " newcert
			fi	
			
			clientCertificate=${newcert:-$clientCertificate}
			
			if [ "$clientCertificate" == "" ]; then
				echo "Certificate name cannot be empty!"
			else
				certProvided=true
				echo
			fi			
		done		
	fi

	dw_write_config
}

dw_write_config() {
	local encpass=$(echo "$demandwarePassword" | openssl enc -aes-128-cbc -a -salt -pass "pass:$demandwareUsername")	
	echo -e "#!/bin/bash\nrequiresClientCertificate=$requiresClientCertificate\ndemandwarePassword=$encpass\ndemandwareUsername=$demandwareUsername\nminifyJS=$minifyJS\nminifyCSS=$minifyCSS" > ${deploydir}/conf/${demandwareServer}.conf
}

dw_upload_build() {
	day=`/bin/date +%Y%m%d`	
	rev=$(scp_revision)
	dwbuild=${day}_${rev}_${build}
    
	dwtarget="https://$demandwareServer/on/demandware.servlet/webdav/Sites/Cartridges/${dwbuild}"
    
	if [ $requiresClientCertificate == true ]; then
        echo
        echo "Uploading with certificate authentication..."
        curl -k -g -u "${demandwareUsername}:${demandwarePassword}" -X MKCOL ${dwtarget} --cert "${deploydir}/certs/$clientCertificate.p12:$clientCertificatePassword"
        curl -k -g -u "${demandwareUsername}:${demandwarePassword}" ${dwtarget}/ -T ${homedir}/build.zip --cert "${deploydir}/certs/$clientCertificate.p12:$clientCertificatePassword"
        echo "Unzipping..."
        curl -k -g -u "${demandwareUsername}:${demandwarePassword}" "${dwtarget}/build.zip" -d method=UNZIP --cert "${deploydir}/certs/$clientCertificate.p12:$clientCertificatePassword"
        echo "Cleaning..." 
		curl -k --request DELETE -u "${demandwareUsername}:${demandwarePassword}" "${dwtarget}/build.zip" -d method=UNZIP --cert "${deploydir}/certs/$clientCertificate.p12:$clientCertificatePassword"
	else
        echo
        echo "Uploading..."
        curl -k -g -u "${demandwareUsername}:${demandwarePassword}" -X MKCOL ${dwtarget}        
		curl -k -g -u "${demandwareUsername}:${demandwarePassword}" ${dwtarget}/ -T "${homedir}/build.zip"
        echo "Unzipping..."
		curl -k -g -u "${demandwareUsername}:${demandwarePassword}" "${dwtarget}/build.zip" -d method=UNZIP
        echo "Cleaning..."
		curl -k --request DELETE -u "${demandwareUsername}:${demandwarePassword}" "${dwtarget}/build.zip" -d method=UNZIP
	fi
	
}
