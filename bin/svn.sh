#!/bin/bash
if [ ! -f "${deploydir}/conf/svn.conf" ]; then	
	touch "${deploydir}/conf/svn.conf"
	echo "Generating new svn configuration."
fi

source ${deploydir}/conf/svn.conf

svnpassword=$(echo "$svnencpassword" | openssl enc -aes-128-cbc -a -d -salt -pass "pass:$svnuser")

scp_write_conf() {
	local encpass=$(echo "$svnpassword" | openssl enc -aes-128-cbc -a -salt -pass "pass:$svnuser")
	echo -e "#!/bin/bash\nsvnrepo=$svnrepo\nsvnuser=$svnuser\nsvnencpassword=$encpass" > ${deploydir}/conf/svn.conf
}

scp_get_repo() {
    repoProvided=false
    while ! $repoProvided; do
		if [ "${svnrepo}" != "" ]; then
			read -p "Please enter your svn repo URL [stored]: " newsvnurl
		else
			read -p "Please enter your svn repo URL: " newsvnurl
		fi
		
		svnrepo=${newsvnurl:-$svnrepo}
        
		if [ "$svnrepo" == "" ]; then
            echo "Repository URL cannot be empty!"
        else
            repoProvided=true
            echo
        fi
    done
}

scp_login() {
	scp_get_repo

    local usernameProvided=false
    while ! $usernameProvided; do
		if [ "${svnuser}" != "" ]; then
			read -p "Please enter your svn username [$svnuser]: " newsvnuser
		else
			read -p "Please enter your svn username: " newsvnuser
		fi
		
		svnuser=${newsvnuser:-$svnuser}
        
		if [ "$svnuser" == "" ]; then
            echo "Username cannot be empty!"
        else
            usernameProvided=true
            echo
        fi
    done

	local passwordProvided=false
    while ! $passwordProvided; do
		if [ "${svnpassword}" != "" ]; then
			read -p "Please enter your svn password [stored password]: " -s newsvnpass
		else
			read -p "Please enter your svn password: " -s newsvnpass
		fi
		
		svnpassword=${newsvnpass:-$svnpassword}
        
		if [ "$svnpassword" == "" ]; then
            echo "Password cannot be empty!"
        else
            passwordProvided=true
            echo
        fi
    done
}

scp_verify_login() {
    scp_login
	scp_write_conf
	svnout=$(svn info $svnrepo --username $svnuser --password $svnpassword --non-interactive)
	if [ "${svnout}" == "" ]; then
		echo "SVN Auth Failed!"
		exit
	fi
}

scp_revision() {
	local svnrev=`svn info $svnrepo --username $svnuser --password $svnpassword --non-interactive | grep '^Revision:' | sed -e 's/^Revision: //'`
	echo "$svnrev"
}

scp_checkout() {
	for cartridge in "${cartridges[@]}"; do		
		cartdir="${homedir}/$cartridge"
		echo
		echo "${cartridge}"
		
		if [ -d "$cartdir" ]; then
			cd "$cartdir"
			svn revert -R .
			svn cleanup
			svn update --username $svnuser --password $svnpassword --force
		else 		
			cd ${homedir}
			svn checkout $(echo $svnrepo/${cartridge} | tr -d '\r') $(echo ${cartridge} | tr -d '\r') --username $svnuser --password $svnpassword
		fi
		cd "${homedir}"
	done
}

scp_exclude() {
	echo ".svn"
}

scp_tag() {
	echo "Commit build information."
}



