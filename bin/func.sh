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
	
	write_conf $demandwareServer "clientCertificate" $clientCertificate
	write_conf_enc $demandwareServer "clientCertificatePassword" $clientCertificatePassword $clientCertificate
	write_conf "deploy" "demandwareCertificateSRL" $demandwareCertificateSRL
	write_conf "deploy" "demandwareCertificateCRT" $demandwareCertificateCRT
	write_conf "deploy" "demandwareCertificateKEY" $demandwareCertificateKEY
	write_conf "deploy" "demandwareCertificatePassword" $demandwareCertificatePassword	
}



write_conf() {
	local file="${deploydir}/conf/$1.conf"
	local setting="$2"
	local value="$3"	
		
	if [ ! -f $file ]; then
		touch $file
	fi	
	
	local confout=""
	while IFS== read pp vv;do
		if [[ "$pp" != "$2" && "$vv" != "" ]]; then
			confout="${confout}$pp=$vv\n"
		fi
	done < $file
	confout="${confout}$setting=$value\n"
	echo -e $confout > $file
	
	return
}

write_conf_enc() {
	local encval=$(echo "$3" | openssl enc -aes-128-cbc -a -salt -pass "pass:$4")
	write_conf $1 $2 $encval
	return
}

read_conf() {
	local file="${deploydir}/conf/$1.conf"
		
	if [ ! -f $file ]; then
		touch $file
	fi	
	
	while IFS='' read -r line || [[ -n $line ]]; do
		local pp="$( cut -d '=' -f 1 <<< "$line" )";
		local vv="$( cut -d '=' -f 2- <<< "$line" )";
		if [ "$pp" == "$2" ]; then
			echo $vv
			return
		fi		
	done < $file
	
	echo $3
	
	return
}

read_conf_enc() {
	local encval=$(read_conf $1 $2)	
	if [ "$encval" != "" ]; then
		local val=$(echo "$encval" | openssl enc -aes-128-cbc -a -d -salt -pass "pass:$3")
		if [ $val ]; then
			echo $val
		fi					
	fi
	return
}

kraken() {
	printf "${bldgrn} ,---.\n( @ @ )\n )${bldred}.-.${bldgrn}(\n'/|||\\\`\n  '|\`${txtrst}\r\n"
}