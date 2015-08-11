inc_build_number() {
	local bn=$(read_conf "deploy" "build" 0)
	build=$(($bn + 1))
	write_conf "deploy" "build" $build
}

zip_cartridges() {		
		echo "Compressing the cartridges for upload ..."
		echo
		
		zipfile="build.zip"		
		cd "$homedir"
		
		rm -f build.zip
        
		for cartridge in "${cartridges[@]}"; do								
			echo "${cartridge}"
			if [ -d "$(echo $cartridge | tr -d '\r')" ]; then
				zip -r $zipfile $(echo $cartridge | tr -d '\r') -x "*$(scp_exclude "$cartridge")*" -x "*.DS_Store"
			fi
			echo
		done		
}

make_clientcert() {
	if [ ! -d "${deploydir}/certs" ]; then
		mkdir "${deploydir}/certs"
		echo "You need to request a server certificate and password from Demandware and put it in the certs directory!"
		exit 1
	else 
		echo "Building client certificate."
	fi
		
	echo
	
	demandwareCertificateSRL=$(prompt "deploy" "demandwareCertificateSRL" $string "" "Please enter the name of the server certificate SRL" true "" true)
	echo
	
	demandwareCertificateCRT=$(prompt "deploy" "demandwareCertificateCRT" $string "" "Please enter the name of the server certificate CRT" true "" true)
	echo
	
	demandwareCertificateKEY=$(prompt "deploy" "demandwareCertificateKEY" $string "" "Please enter the name of the server certificate KEY" true "" true)
	echo
	
	demandwareCertificatePassword=$(secure_prompt "deploy" "demandwareCertificatePassword" $string "" "Please enter the password for the server certificate" true "$demandwareCertificateSRL" true)
	echo

	clientCertificate=$(prompt $demandwareServer "clientCertificate" $string "" "Please enter the client certificate name" true "" true)
	echo
	
	clientCertificatePassword=$(prompt $demandwareServer "clientCertificatePassword" $string "" "Please enter the client certificate name" true "$clientCertificate" true)
	echo
	
	openssl req -new -newkey rsa:512 -nodes -out ${deploydir}/certs/$clientCertificate.req -keyout ${deploydir}/certs/$clientCertificate.key -subj "$certSubj" -passout "pass:$clientCertificatePassword"		
	openssl x509 -CA ${deploydir}/certs/$demandwareCertificateCRT -CAkey ${deploydir}/certs/$demandwareCertificateKEY -CAserial ${deploydir}/certs/$demandwareCertificateSRL -req -in ${deploydir}/certs/$clientCertificate.req -out ${deploydir}/certs/$clientCertificate.pem -days 360 -passin "pass:$demandwareCertificatePassword"
	openssl pkcs12 -export -in ${deploydir}/certs/$clientCertificate.pem -inkey ${deploydir}/certs/$clientCertificate.key -certfile ${deploydir}/certs/$demandwareCertificateCRT -name "$clientCertificate" -out ${deploydir}/certs/$clientCertificate.p12 -passout "pass:$clientCertificatePassword"
	
	write_conf $demandwareServer "clientCertificate" $clientCertificate
	write_conf_enc $demandwareServer "clientCertificatePassword" $clientCertificatePassword $clientCertificate
	write_conf "deploy" "demandwareCertificateSRL" $demandwareCertificateSRL
	write_conf "deploy" "demandwareCertificateCRT" $demandwareCertificateCRT
	write_conf "deploy" "demandwareCertificateKEY" $demandwareCertificateKEY
	write_conf_enc "deploy" "demandwareCertificatePassword" $demandwareCertificatePassword $demandwareCertificateSRL
}

kraken() {
	printf "${bldgrn} ,---.\n( @ @ )\n )${bldred}.-.${bldgrn}(\n'/|||\\\`\n  '|\`${txtrst}\r\n"
}