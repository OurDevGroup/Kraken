requiresClientCertificate=false
certSubj=$(read_conf "deploy" "certSubj" "/C=US/ST=Some State/L=Some City/O=Some Company/OU=IT/CN=example.com")

dw_configure() {
	
	demandwareServer=$(prompt "deploy" "demandwareServer" $string "" "Please enter the target Demandware server" true "" true)
	echo
		
	if [ -f "${deploydir}/conf/${demandwareServer}.conf" ]; then
		source "${deploydir}/conf/${demandwareServer}.conf"
	else
		touch "${deploydir}/conf/${demandwareServer}.conf"
		echo "Generating new server configuration."
		echo
	fi	

	demandwareUsername=$(prompt $demandwareServer "demandwareUsername" $string "" "Please enter the username for $demandwareServer" true "" true)
	echo 
	
	demandwarePassword=$(secure_prompt $demandwareServer "demandwarePassword" $string "" "Please enter the password for $demandwareServer" true "$demandwareUsername" true)	
	echo
	
	requiresClientCertificate=$(prompt $demandwareServer "requiresClientCertificate" $bool false "Does the server require a client certificate" true "" true)
	echo
		
	local genCert=false
	if [ $requiresClientCertificate == true ]; then			
		local genCert=$(prompt $demandwareServer "generateClientCert" $bool false "Do you need to generate a client certificate" true "" false)
		echo
		if [ $genCert == true ]; then
			make_clientcert
		fi
	fi
		
	if [ $requiresClientCertificate == true ] && [ $genCert == false ]; then				
		clientCertificate=$(prompt $demandwareServer "clientCertificate" $string "" "Please enter the client certificate file" true "" true)
		echo
		
		clientCertificatePassword=$(secure_prompt $demandwareServer "clientCertificatePassword" $string "" "Please enter the client certificate password" true "$clientCertificate" true)
		echo		
	fi

	write_conf "deploy" "certSubj" "$certSubj"
}

dw_upload_build() {
	local day=`/bin/date +%Y%m%d`	
	local rev=$(scp_revision)
	local bn=$(read_conf "deploy" "build" 0)
	dwbuild=${day}_${rev}_${bn}
    
	dwtarget="https://$demandwareServer/on/demandware.servlet/webdav/Sites/Cartridges/${dwbuild}"
	
	if [ $requiresClientCertificate == true ]; then
		local certExt="pem"
		if [ os == "osx" ]; then
			local certExt="p12"
		fi	
        echo        
        echo "Uploading with certificate authentication..."
        curl -k -g -u "${demandwareUsername}:${demandwarePassword}" -X MKCOL ${dwtarget} --cert "${deploydir}/certs/$clientCertificate.$certExt:$clientCertificatePassword" --key ${deploydir}/certs/$clientCertificate.key
        curl -k -g -u "${demandwareUsername}:${demandwarePassword}" ${dwtarget}/ -T ${homedir}/build.zip --cert "${deploydir}/certs/$clientCertificate.$certExt:$clientCertificatePassword" --key ${deploydir}/certs/$clientCertificate.key
        echo "Unzipping..."
        curl -k -g -u "${demandwareUsername}:${demandwarePassword}" "${dwtarget}/build.zip" -d method=UNZIP --cert "${deploydir}/certs/$clientCertificate.$certExt:$clientCertificatePassword" --key ${deploydir}/certs/$clientCertificate.key
        echo "Cleaning..." 
		curl -k --request DELETE -u "${demandwareUsername}:${demandwarePassword}" "${dwtarget}/build.zip" -d method=UNZIP --cert "${deploydir}/certs/$clientCertificate.$certExt:$clientCertificatePassword" --key ${deploydir}/certs/$clientCertificate.key
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
