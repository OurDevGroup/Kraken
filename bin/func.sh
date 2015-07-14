build_number() {
	build=$(($build + 1))
	write_config
}

zip_cartridges() {
		echo
		echo "Compressing the cartridges for upload ..."
		
		zipfile="build.zip"		
		cd "$homedir"
        
		for cartridge in "${cartridges[@]}"; do					
			echo
			echo "${cartridge}"
			if [ -d "$(echo $cartridge | tr -d '\r')" ]; then
				zip -r $zipfile $(echo $cartridge | tr -d '\r') -x "*$(scp_exclude)*" -x "*.DS_Store"
			fi
		done		
}

write_config() {
	local encpass=$(echo "$demandwareCertificatePassword" | openssl enc -aes-128-cbc -a -salt -pass "pass:$demandwareCertificateSRL")
	local encclientpass=$(echo "$clientCertificatePassword" | openssl enc -aes-128-cbc -a -salt -pass "pass:$clientCertificate")
	echo -e "#!/bin/bash\nbuild=$build\ndemandwareServer=$demandwareServer\ndemandwareCertificateSRL=$demandwareCertificateSRL\ndemandwareCertificateCRT=$demandwareCertificateCRT\ndemandwareCertificateKEY=$demandwareCertificateKEY\ndemandwareCertificatePassword=$encpass\ncertSubj=\"$certSubj\"\nclientCertificate=$clientCertificate\nclientCertificatePassword=$encclientpass" > ${deploydir}/conf/deploy.conf
}

make_clientcert() {
	echo
	if [ ! -d "${deploydir}/certs" ]; then
		mkdir "${deploydir}/certs"
		echo "You need to request a server certificate and password from Demandware and put it in the certs directory!"
		exit 1
	else 
		echo "Building client certificate."
	fi
		
	echo
    local srvcertprovided=false
    while ! $srvcertprovided; do	
		if [ "${demandwareCertificateSRL}" != "" ]; then
			read -p "Please enter the name of the server certificate SRL [$demandwareCertificateSRL]: " newdwcert
		else
			read -p "Please enter the name of the server certificate SRL: " newdwcert
		fi		
		demandwareCertificateSRL=${newdwcert:-$demandwareCertificateSRL}
		
		if [ "${demandwareCertificateCRT}" != "" ]; then
			read -p "Please enter the name of the server certificate CRT [$demandwareCertificateCRT]: " newdwcert
		else
			read -p "Please enter the name of the server certificate CRT: " newdwcert
		fi		
		demandwareCertificateCRT=${newdwcert:-$demandwareCertificateCRT}	

		if [ "${demandwareCertificateKEY}" != "" ]; then
			read -p "Please enter the name of the server certificate KEY [$demandwareCertificateKEY]: " newdwcert
		else
			read -p "Please enter the name of the server certificate KEY: " newdwcert
		fi		
		demandwareCertificateKEY=${newdwcert:-$demandwareCertificateKEY}		
		
		if [ "$newdwcert" != "" ] || [ "$demandwareCertificatePassword" == "" ]; then
			demandwareCertificatePassword=""
		fi		

		if [ "$demandwareCertificateSRL" == "" ] || [ "$demandwareCertificateCRT" == "" ] || [ "$demandwareCertificateKEY" == "" ]; then
            echo "Demandware certificate names cannot be empty!"
        else
            srvcertprovided=true
            echo
        fi
    done	
	
	echo
    local srvpassprovided=false
    while ! $srvpassprovided; do	
		if [ "${demandwareCertificatePassword}" != "" ]; then
			read -p "Please enter the password for the server certificate [stored password]: " -s newdwcertpass
		else
			read -p "Please enter the password for the server certificate: " -s newdwcertpass
		fi
		
		demandwareCertificatePassword=${newdwcertpass:-$demandwareCertificatePassword}
        
		if [ "$demandwareCertificateSRL" == "" ]; then
            echo "Demandware certificate name cannot be empty!"
        else
            srvpassprovided=true
            echo
        fi
    done	
	
	echo
    local clientcertprovided=false
    while ! $clientcertprovided; do	
		read -p "Please enter the client certificate name [build]: " clientCertificate
		
		clientCertificate=${clientCertificate:-"build"}
        
		if [ "$clientCertificate" == "" ]; then
            echo "Client certificate name cannot be empty!"
        else
            clientcertprovided=true
            echo
        fi
    done	
	
	echo
    local clientcertpassprovided=false
    while ! $clientcertpassprovided; do	
		read -p "Please enter the client certificate password: " -s clientCertificatePassword
		
		if [ "$clientCertificatePassword" == "" ]; then
            echo "Client certificate password cannot be empty!"
        else
            clientcertpassprovided=true
            echo
        fi
    done

	openssl req -new -newkey rsa:512 -nodes -out ${deploydir}/certs/$clientCertificate.req -keyout ${deploydir}/certs/$clientCertificate.key -subj "$certSubj" -passout "pass:$clientCertificatePassword"
	openssl x509 -CA ${deploydir}/certs/$demandwareCertificateCRT -CAkey ${deploydir}/certs/$demandwareCertificateKEY -CAserial ${deploydir}/certs/$demandwareCertificateSRL -req -in ${deploydir}/certs/$clientCertificate.req -out ${deploydir}/certs/$clientCertificate.pem -days 360 -passin "pass:$demandwareCertificatePassword"
	openssl pkcs12 -export -in ${deploydir}/certs/$clientCertificate.pem -inkey ${deploydir}/certs/$clientCertificate.key -certfile ${deploydir}/certs/$demandwareCertificateCRT -name "$clientCertificate" -out ${deploydir}/certs/$clientCertificate.p12 -passout "pass:$clientCertificatePassword"
	
	write_config
}

kraken() {
	printf "${bldgrn} ,---.\n( @ @ )\n )${bldred}.-.${bldgrn}(\n'/|||\\\`\n  '|\`${txtrst}\r\n"
}