#!/bin/bash
git_repo_md5() {

	if [ "$1" == "" ]; then
		local gitrepo=$(read_conf "git" "repo")
		local baserepo=$gitrepo
	else
		local gitrepo=$(read_conf "git" "provider.$1.repo")
		local baserepo=$gitrepo
		#if [[ "$1" != "" && "$gitrepo" == *$cartridge ]]; then
		#	local l=$[${#gitrepo} - ${#cartridge}]
		#	local baserepo=${gitrepo:0:$l}
		#fi
	fi

	repomd5=$(echo -n $(_md5 "$baserepo") | cut -d ' ' -f 1)
	echo $repomd5

	return
}

git_get_repo() {
	git config --global http.postBuffer 524288000

	if [ "$1" == "" ]; then
		gitrepo=$(prompt "git" "repo" $string "" "Please enter your Git repo URL (.git)" true)
		echo
		gitpath=$(prompt "git" "path" $string "." "Please enter your Git repo catridge path" false)
		echo
		gitbranch=$(prompt "git" "branch" $string "master" "Please enter your Git repo branch" true)
		echo
	else
		baserepo=$(read_conf "git" "baserepo")

		local a=$([ "$1" == "" ] && echo "" || echo " for $1")
		gitrepo=$(prompt "git" "provider.$1.repo" $string "$baserepo" "Please enter your Git repo URL${a} (.git)" true)
		echo
		gitpath=$(prompt "git" "provider.$1.path" $string "$gitpath" "Please enter your Git repo path${a}" true)
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
	git_get_repo $1
	git config --global credential.helper cache
}

git_revision() {
	local provider=$(read_conf "scp" "provider" "")

	if [ "$provider" == "multi" ]; then
		local svnrepo=$(read_conf "git" "provider.$1.repo")
		local cartdir="$homedir/$1"
		cd "$cartdir"
	else
		local cartpath=$(scp_cartridge_path ${cartridges[0]})
		#local cartdir="$homedir/$cartpath"
		local cartdir="$homedir/$1"
		cd "$cartdir"
	fi

	local gitrev=`git rev-list --count --first-parent HEAD`

	cd $homedir

	echo "$gitrev"
}

git_checkout() {
	echo "git checkout"
	local cartpath=$(scp_cartridge_path $1)
	local cartdir="${homedir}/$cartpath"
	local repomd5="c$(git_repo_md5 $1)"

	if [ -d "$cartdir" ]; then
		cd "$cartdir"
		local isCloned=${!repomd5}

		if [ "$isCloned" != "true" ]; then
			if [ "$provider" == "multi" ]; then
				local branch=$(read_conf "git" "provider.$1.branch")
			else
				local branch=$(read_conf "git" "branch")
			fi

			git fetch --all
			git reset --hard origin/${branch}
			git clean -d -f

			git checkout $branch
			git pull origin $branch
			eval "$repomd5=true"
		fi
	else
		local provider=$(read_conf "scp" "provider" "")

		if [ "$provider" == "multi" ]; then
			local cartrepo=$(read_conf "git" "provider.$1.repo")
			local branch=$(read_conf "git" "provider.$1.branch")
		else
			local cartrepo=$(read_conf "git" "repo")
			local branch=$(read_conf "git" "branch")
		fi

		cd ${homedir}

		local repomd5="c$(git_repo_md5 $1)"
		local isCloned=${!repomd5}
		if [ "$isCloned" != "true" ]; then
			git clone $cartrepo
			git checkout $branch
			eval "$repomd5=true"
		fi
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
