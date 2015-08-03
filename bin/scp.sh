source ${deploydir}/bin/svn.sh
source ${deploydir}/bin/git.sh

scp_verify_login() {
	if [ ! $scpVerified ]; then
		local provider=$(read_conf "scp" "provider" "")
		echo
		if [ "$provider" == "multi" ]; then
			for cartridge in "${cartridges[@]}"; do	
				local cartProvider=$(read_conf "scp" "provider.$cartridge")
				if [ "${cartProvider^^}" == "SVN" ]; then
					svn_verify_login "$cartridge" 
				fi
			done					
		else
			if [ "${provider^^}" == "SVN" ]; then
				svn_verify_login  
			fi
		fi		
	fi
}

scp_checkout () {
	local provider=$(read_conf "scp" "provider" "")
	if [ "$provider" == "multi" ]; then
		for cartridge in "${cartridges[@]}"; do	
			local cartProvider=$(read_conf "scp" "provider.$cartridge")
			echo "${cartridge}"
			if [ "${cartProvider^^}" == "SVN" ]; then
				svn_checkout "$cartridge" 
			fi
		done					
	else
		for cartridge in "${cartridges[@]}"; do		
			echo
			echo "${cartridge}"
			if [ "${provider^^}" == "SVN" ]; then
				svn_checkout "$cartridge" 
			fi
		done
	fi
}

scp_tag() {
	local provider=$(read_conf "scp" "provider" "svn")
	if [ "$provider^^" == "SVN" ]; then
		svn_tag
	fi
}

scp_configure() {
	local provider=$(read_conf "scp" "provider" "")
	local configProvider=false
	if [ "$provider" != "" ]; then
		local configProvider=$(prompt "scp" "configProvider" $bool false "Do you want to re-configure a source control provider" true "" false)
		echo
	fi
	exit 1
	if [ "$provider" == "" ] || [ $configProvider == true ]; then	
		if [ "$provider" == "multi" ]; then
			local eachCartridge=true
		else
			local eachCartridge=false;
		fi
		local eachCartridge=$(prompt "scp" "eachCartridge" $bool $eachCartridge "Do you want to configure a source control provider for each cartridge" true "" false)
		
		echo
		if [ $eachCartridge == true ]; then
			write_conf "scp" "provider" "multi"
			
			for cartridge in "${cartridges[@]}"; do					
				local provider=$(prompt "scp" "provider.$cartridge" $string "svn" "What source control provider do you use for $cartridge (svn/git)" true)
				echo		
				if [ "${provider^^}" == "SVN" ]; then
					svn_verify_login "$cartridge" 
				fi
			done					
		else
			local provider=$(prompt "scp" "provider" $string "svn" "What source control provider do you use (svn/git)" true)
			echo
			if [ "${provider^^}" == "SVN" ]; then
				svn_verify_login 
			fi
		fi				
	fi	
	scpVerified=true
}

