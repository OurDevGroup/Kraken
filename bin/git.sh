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

git_get_repo() {
	if [ "$1" == "" ]; then
		gitrepo=$(prompt "git" "repo" $string "" "Please enter your Git repo URL (.git)" true)
		echo
		gitpath=$(prompt "git" "path" $string "" "Please enter your Git repo catridge path" true)
		echo
		gitbranch=$(prompt "git" "branch" $string "master" "Please enter your Git repo branch" true)
		echo
	else
		baserepo=$(read_conf "git" "baserepo")
		
		local a=$([ "$1" == "" ] && echo "" || echo " for $1")
		gitrepo=$(prompt "git" "provider.$1.repo" $string "$baserepo$cartridge" "Please enter your Git repo URL${a} (.git)" true)
		echo
		gitpath=$(prompt "git" "provider.$1.path" $string "$baserepo$cartridge" "Please enter your Git repo path${a}" true)
		echo
		gitbranch=$(prompt "git" "provider.$1.branch" $string "master" "Please enter your Git repo branch${a}" true)
		echo
		
		if [[ "$1" != "" && "$gitrepo" == *$cartridge ]]; then
			local l=$[${#gitrepo} - ${#cartridge}]
			local baserepo=${gitrepo:0:$l}
			write_conf "git" "baserepo" "$baserepo"
		fi		
	fi
	echo
}

git_verify_login() {
	git config --global credential.helper cache
}

git_revision() {
	local provider=$(read_conf "scp" "provider" "")

	if [ "$provider" == "multi" ]; then
		local svnrepo=$(read_conf "git" "provider.$1.repo")	
		local cartdir="${homedir}/$1"
		cd "$cartdir"		
	else
		local svnrepo=$(read_conf "git" "repo")
	fi

	local gitrev=`git log --pretty=format:'%h' -n 1`
	
	cd ${homedir}
	echo "$gitrev"
}

git_checkout() {
	local cartdir="${homedir}/$1"
	
	if [ -d "$cartdir" ]; then
		cd "$cartdir"
		
		git checkout .
		git reset
		git revert ...
		git clean -f 
		git clean -d	
		
		if [ "$provider" == "multi" ]; then
			local branch=$(read_conf "git" "provider.$1.branch")			
		else
			local branch=$(read_conf "git" "branch")
		fi
		
		git pull $branch
	else 		
		local provider=$(read_conf "scp" "provider" "")

		if [ "$provider" == "multi" ]; then
			local cartrepo=$(read_conf "git" "provider.$1.repo")			
		else
			local cartrepo=$(read_conf "git" "repo")
		fi
		
		cd ${homedir}
		
		git clone cartrepo	
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
