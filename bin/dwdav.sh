requiresClientCertificate=false
certSubj=$(read_conf "deploy" "certSubj" "/C=US/ST=Some State/L=Some City/O=Some Company/OU=IT/CN=example.com")

dw_configure() {
	demandwareServer=$(read_conf "deploy" "demandwareServer" $demandwareServer)
	
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
	
	write_conf "deploy" "demandwareServer" $demandwareServer
	
	if [ -f "${deploydir}/conf/${demandwareServer}.conf" ]; then
		source "${deploydir}/conf/${demandwareServer}.conf"
	else
		touch "${deploydir}/conf/${demandwareServer}.conf"
		echo "Generating new server configuration."
		echo
	fi
	
	demandwareUsername=$(read_conf $demandwareServer "demandwareUsername")		
	local dwUserProvided=false
    while ! $dwUserProvided; do
		if [ "${demandwareUsername}" != "" ]; then
			read -p "Please enter the username for $demandwareServer [$demandwareUsername]: " newdwuser
		else
			read -p "Please enter the username for $demandwareServer: " newdwuser
		fi
		
		demandwareUsername=${newdwuser:-$demandwareUsername}
        
		if [ "$demandwareUsername" == "" ]; then
            echo "Username cannot be empty!"
        else
            dwUserProvided=true
            echo
        fi
    done	
	write_conf $demandwareServer "demandwareUsername" $demandwareUsername

	demandwarePassword=$(read_conf_enc $demandwareServer "demandwarePassword" $demandwareUsername)		
	local dwPassProvided=false	
    while ! $dwPassProvided; do
		if [ "$demandwarePassword" != "" ]; then
			read -p "Please enter the password for $demandwareServer [stored password]: " -s newdwpass
		else
			read -p "Please enter the password for $demandwareServer: " -s newdwpass
		fi
		
		demandwarePassword=${newdwpass:-$demandwarePassword}
        
		if [ "$demandwarePassword" == "" ]; then
            echo "Password cannot be empty!"
        else
            dwPassProvided=true
            echo
        fi
    done
	write_conf_enc $demandwareServer "demandwarePassword" $demandwarePassword $demandwareUsername	
	
	echo
	requiresClientCertificate=$(read_conf $demandwareServer "requiresClientCertificate")
	if [[ $requiresClientCertificate == true ]]; then
		read -p "Does the server require a client certificate [Y/n]: " needsCert
		needsCert=${needsCert:-Y}
	else
		read -p "Does the server require a client certificate [y/N]: " needsCert
		needsCert=${needsCert:-N}
	fi
	
	if [[ "$(upper $needsCert)" == "Y" ]]; then
		requiresClientCertificate=true
		echo
		read -p "Do you need to generate a client certificate [y/N]: " genCert
		genCert=${genCert:-N}
		if [ "$(upper $genCert)" == "Y" ]; then
			make_clientcert
		fi
	else
		requiresClientCertificate=false
	fi
	write_conf $demandwareServer "requiresClientCertificate" $requiresClientCertificate
	
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
		
		local certPassProvided=false
		echo
		while ! $certPassProvided; do
			if [ "${clientCertificate}" != "" ]; then
				read -p "Please enter the client certificate password: " clientCertificatePassword
			fi

			if [ "$clientCertificatePassword" == "" ]; then
				echo "Certificate password cannot be empty!"
			else
				certPassProvided=true
				echo
			fi			
		done		
		
		write_conf $demandwareServer "clientCertificate" $clientCertificate
		write_conf_enc $demandwareServer "clientCertificatePassword" $clientCertificatePassword $clientCertificate
	fi

	write_conf "deploy" "certSubj" $certSubj
}

dw_upload_build() {
	local day=`/bin/date +%Y%m%d`	
	local rev=$(scp_revision)
	local bn=$(read_conf "deploy" "build" 0)
	dwbuild=${day}_${rev}_${bn}
    
	dwtarget="https://$demandwareServer/on/demandware.servlet/webdav/Sites/Cartridges/${dwbuild}"
	
	if [ $requiresClientCertificate == true ]; then
        echo
        echo "Uploading with certificate authentication..."
        curl -k -g -u "${demandwareUsername}:${demandwarePassword}" -X MKCOL ${dwtarget} --cert "${deploydir}/certs/$clientCertificate.pem:$clientCertificatePassword" --key ${deploydir}/certs/$clientCertificate.key
        curl -k -g -u "${demandwareUsername}:${demandwarePassword}" ${dwtarget}/ -T ${homedir}/build.zip --cert "${deploydir}/certs/$clientCertificate.pem:$clientCertificatePassword" --key ${deploydir}/certs/$clientCertificate.key
        echo "Unzipping..."
        curl -k -g -u "${demandwareUsername}:${demandwarePassword}" "${dwtarget}/build.zip" -d method=UNZIP --cert "${deploydir}/certs/$clientCertificate.pem:$clientCertificatePassword" --key ${deploydir}/certs/$clientCertificate.key
        echo "Cleaning..." 
		curl -k --request DELETE -u "${demandwareUsername}:${demandwarePassword}" "${dwtarget}/build.zip" -d method=UNZIP --cert "${deploydir}/certs/$clientCertificate.pem:$clientCertificatePassword" --key ${deploydir}/certs/$clientCertificate.key
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
