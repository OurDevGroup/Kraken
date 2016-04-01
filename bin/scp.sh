source ${deploydir}/bin/svn.sh
source ${deploydir}/bin/git.sh

scp_verify_login() {
	if [ ! $scpVerified ]; then
		local provider=$(read_conf "scp" "provider" "")

		if [ "$provider" == "multi" ]; then
			for cartridge in "${cartridges[@]}"; do
				local cartProvider=$(read_conf "scp" "provider.$cartridge")
				if [ "$(upper $cartProvider)" == "SVN" ]; then
					svn_verify_login "$cartridge"
				elif [ "$(upper $cartProvider)" == "GIT" ]; then
					git_verify_login "$cartridge"
				fi
			done
		else
			if [ "$(upper $provider)" == "SVN" ]; then
				svn_verify_login
			elif [ "$(upper $provider)" == "GIT" ]; then
				git_verify_login
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
			if [ "$(upper $cartProvider)" == "SVN" ]; then
				svn_checkout "$cartridge"
			elif [ "$(upper $cartProvider)" == "GIT" ]; then
				git_checkout "$cartridge"
			fi
		done
	else
		for cartridge in "${cartridges[@]}"; do
			echo
			echo "${cartridge}"
			if [ "$(upper $provider)" == "SVN" ]; then
				svn_checkout "$cartridge"
			elif [ "$(upper $provider)" == "GIT" ]; then
				git_checkout "$cartridge"
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

				if [ "$(upper $provider)" == "SVN" ]; then
					svn_verify_login "$cartridge"
				elif [ "$(upper $provider)" == "GIT" ]; then
					git_verify_login "$cartridge"
				fi
			done
		else
			local provider=$(prompt "scp" "provider" $string "svn" "What source control provider do you use (svn/git)" true)
			echo
			if [ "$(upper $provider)" == "SVN" ]; then
				svn_verify_login
			elif [ "$(upper $provider)" == "GIT" ]; then
				git_verify_login
			fi
		fi
	fi
	scpVerified=true
}

scp_revision() {
	local provider=$(read_conf "scp" "provider" "")
	if [ "$provider" == "multi" ]; then
		local cartridge=$1
		if [ "$1" == "" ]; then
			local cartridge=${cartridges[0]}
		fi
		local cartProvider=$(read_conf "scp" "provider.$cartridge")
		if [ "$(upper $cartProvider)" == "SVN" ]; then
			echo $(svn_revision $cartridge)
		elif [ "$(upper $provider)" == "GIT" ]; then
			echo $(git_revision $cartridge)
		fi
	else
		if [ "$(upper $provider)" == "SVN" ]; then
			echo $(svn_revision)
		elif [ "$(upper $provider)" == "GIT" ]; then
			echo $(git_revision)
		fi
	fi
}

scp_exclude() {
	local provider=$(read_conf "scp" "provider" "")
	if [ "$provider" == "multi" ]; then
		local cartridge=$1
		if [ "$1" == "" ]; then
			local cartridge=${cartridges[0]}
		fi
		local cartProvider=$(read_conf "scp" "provider.$cartridge")
		if [ "$(upper $cartProvider)" == "SVN" ]; then
			echo $(svn_exclude)
		elif [ "$(upper $cartProvider)" == "GIT" ]; then
			echo $(git_exclude)
		fi
	else
		if [ "$(upper $provider)" == "SVN" ]; then
			echo $(svn_exclude)
		elif [ "$(upper $provider)" == "GIT" ]; then
			echo $(git_exclude)
		fi
	fi
}

scp_cartridge_path() {
	local provider=$(read_conf "scp" "provider" "")
	if [ "$provider" == "multi" ]; then
		local cartProvider=$(read_conf "scp" "provider.$1")
		if [ "$(upper $cartProvider)" == "SVN" ]; then
			echo $1
		elif [ "$(upper $cartProvider)" == "GIT" ]; then
			gitRepo=$(read_conf "git" "provider.$1.repo")
			gitFile=$(echo "$gitRepo" | rev | cut -d"/" -f1 | rev)
			repoDir=$(echo "$gitFile" | cut -d"." -f1)
			cartPath=$(read_conf "git" "provider.$1.path")
			if [ "$cartPath" == "" ]; then
				echo "$repoDir"
			else
				echo "$repoDir/$cartPath"
			fi
		fi
	else
		if [ "$(upper $provider)" == "SVN" ]; then
			echo $1
		elif [ "$(upper $provider)" == "GIT" ]; then
			gitRepo=$(read_conf "git" "repo")
			gitFile=$(echo "$gitRepo" | rev | cut -d"/" -f1 | rev)
			repoDir=$(echo "$gitFile" | cut -d"." -f1)
			cartPath=$(read_conf "git" "path")
			if [ "$cartPath" == "" ]; then
				echo "$repoDir/$1"
			else
				echo "$repoDir/$cartPath/$1"
			fi
		fi
	fi
}
