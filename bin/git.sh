#!/bin/bash
git_repo_md5() {	
	if [ "$1" == "" ]; then
		local gitrepo=$(read_conf "git" "repo")
		local baserepo=$gitrepo
	else
		local gitrepo=$(read_conf "git" "provider.$1.repo")
		if [[ "$1" != "" && "$gitrepo" == *$cartridge ]]; then
			local l=$[${#gitrepo} - ${#cartridge}]
			local baserepo=${gitrepo:0:$l}			
		fi
	fi	
	
	repomd5=$(echo -n $baserepo | md5sum | cut -d ' ' -f 1)
	echo $repomd5
	
	return
}

svn_get_repo() {
	if [ "$1" == "" ]; then
		gitrepo=$(prompt "git" "repo" $string "" "Please enter your Git repo URL (.git)" true)
		gitpath=$(prompt "git" "repo" $string "" "Please enter your Git repo catridge path" true)
	else
		baserepo=$(read_conf "git" "baserepo")
		
		local a=$([ "$1" == "" ] && echo "" || echo " for $1")
		gitrepo=$(prompt "git" "provider.$1.repo" $string "$baserepo$cartridge" "Please enter your Git repo URL${a} (.git)" true)
		gitpath=$(prompt "git" "provider.$1.path" $string "$baserepo$cartridge" "Please enter your Git repo path${a}" true)
				
		if [[ "$1" != "" && "$gitrepo" == *$cartridge ]]; then
			local l=$[${#gitrepo} - ${#cartridge}]
			local baserepo=${gitrepo:0:$l}
			write_conf "git" "baserepo" "$baserepo"
		fi		
	fi
	echo
}

git_login() {
	git_get_repo "$1"	

	local repomd5=$(git_repo_md5)
	
	gituser=$(prompt "git" "$repomd5.user" $string "" "Please enter your Git username" true)
	echo
	
	gitpassword=$(secure_prompt "git" "$repomd5.pass" $string "" "Please enter your Git password" true $gituser)
	echo
}

git_verify_login() {
    git_login "$1"
	
	local repomd5=$(git_repo_md5)
	local isAuthed=$(eval "echo \$${repomd5}")
	
	if [ ! $isAuthed ]; then
		out=$(svn info $svnrepo --username $svnuser --password $svnpassword --non-interactive)
		
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

git_revision() {
	local svnrev=`svn info $svnrepo --username $svnuser --password $svnpassword --non-interactive | grep '^Revision:' | sed -e 's/^Revision: //'`
	echo "$svnrev"
}

git_checkout() {
	local gituser=$(read_conf "git" "gituser")
	local gitpassword=$(read_conf_enc "git" "gitpassword" $gituser)	
	local cartdir="${homedir}/$1"
	
	if [ -d "$cartdir" ]; then
		cd "$cartdir"
		svn revert -R .
		svn cleanup
		svn update --username $svnuser --password $svnpassword --force
	else 		
		local provider=$(read_conf "scp" "provider" "")

		if [ "$provider" == "multi" ]; then
			local cartrepo=$(read_conf "svn" "provider.$1.repo")			
		else
			local cartrepo=$(read_conf "svn" "repo")
		fi
		
		cd ${homedir}
		svn checkout $(echo $cartrepo | tr -d '\r') $(echo ${cartridge} | tr -d '\r') --username $svnuser --password $svnpassword
	fi
	cd "${homedir}"
	echo
}

git_exclude() {
	echo ".git"
}

git_tag() {
	echo "Commit build information."
}
