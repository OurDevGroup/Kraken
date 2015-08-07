#!/bin/bash
svn_repo_md5() {	
	if [ "$1" == "" ]; then
		local svnrepo=$(read_conf "svn" "repo")
		local baserepo=$svnrepo
	else
		local svnrepo=$(read_conf "svn" "provider.$1.repo")
		if [[ "$1" != "" && "$svnrepo" == *$cartridge ]]; then
			local l=$[${#svnrepo} - ${#cartridge}]
			local baserepo=${svnrepo:0:$l}			
		fi
	fi	
	
	repomd5=$(echo -n $baserepo | md5sum | cut -d ' ' -f 1)
	echo $repomd5
	
	return
}

svn_get_repo() {
	if [ "$1" == "" ]; then
		svnrepo=$(prompt "svn" "repo" $string "" "Please enter your SVN repo URL" true)
	else
		baserepo=$(read_conf "svn" "baserepo")
		
		local a=$([ "$1" == "" ] && echo "" || echo " for $1")
		svnrepo=$(prompt "svn" "provider.$1.repo" $string "$baserepo$cartridge" "Please enter your SVN repo URL${a}" true)
				
		if [[ "$1" != "" && "$svnrepo" == *$cartridge ]]; then
			local l=$[${#svnrepo} - ${#cartridge}]
			local baserepo=${svnrepo:0:$l}
			write_conf "svn" "baserepo" "$baserepo"
		fi		
	fi
	echo
}

svn_login() {
	svn_get_repo "$1"	

	local repomd5=$(svn_repo_md5)
	
	svnuser=$(prompt "svn" "$repomd5.user" $string "" "Please enter your svn username" true)
	echo
	
	svnpassword=$(secure_prompt "svn" "$repomd5.pass" $string "" "Please enter your svn password" true $svnuser)
	echo
}

svn_verify_login() {
    svn_login "$1"
	
	local repomd5=$(svn_repo_md5)
	local isAuthed=$(eval "echo \$${repomd5}")
	
	if [ ! $isAuthed ]; then
		svnout=$(svn info $svnrepo --username $svnuser --password $svnpassword --non-interactive)
		
		if [ "${svnout}" == "" ]; then
			echo "SVN Auth Failed!"
			exit
		else		
			echo
			echo "SVN Authenticated."
			local repomd5=$(svn_repo_md5)
			eval "${repomd5}=true"
		fi
	fi
	echo
}

svn_revision() {
	local provider=$(read_conf "scp" "provider" "")

	if [ "$provider" == "multi" ]; then
		local svnrepo=$(read_conf "svn" "provider.$1.repo")			
	else
		local svnrepo=$(read_conf "svn" "repo")
	fi
	
	local repomd5=$(svn_repo_md5)
	local svnuser=$(read_conf "svn" "$repomd5.user")
	local svnpassword=$(read_conf_enc "svn" "$repomd5.pass" $svnuser)
	
	local svnrev=`svn info $svnrepo --username $svnuser --password $svnpassword --non-interactive | grep '^Revision:' | sed -e 's/^Revision: //'`
	echo "$svnrev"
}

svn_checkout() {
	local provider=$(read_conf "scp" "provider" "")

	if [ "$provider" == "multi" ]; then
		local cartrepo=$(read_conf "svn" "provider.$1.repo")			
	else
		local cartrepo=$(read_conf "svn" "repo")
	fi

	local repomd5=$(svn_repo_md5)
	local svnuser=$(read_conf "svn" "$repomd5.user")
	local svnpassword=$(read_conf_enc "svn" "$repomd5.pass" $svnuser)	
	
	local cartdir="${homedir}/$1"
	
	if [ -d "$cartdir" ]; then
		cd "$cartdir"
		svn cleanup
		svn revert -R .		
		svn update --username $svnuser --password $svnpassword --force
	else 		
		cd ${homedir}
		svn checkout $(echo $cartrepo | tr -d '\r') $(echo ${cartridge} | tr -d '\r') --username $svnuser --password $svnpassword
	fi
	cd "${homedir}"
	echo
}

svn_exclude() {
	echo ".svn"
}

svn_tag() {
	echo "Commit build information."
}



