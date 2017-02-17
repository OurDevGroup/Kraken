less_compile() {
  write_status "Compiling Less Files"

  local demandwareServer=$(read_conf "deploy" "demandwareServer" $demandwareServer)
	local compileLess=$(prompt $demandwareServer "compileLess" $bool false "Would you like to compile all Less .less files" true "" true)
	echo

	if [ $compileLess == true ]; then
    command -v asdfs >/dev/null 2>&1 || {
      echo
      local installNode="N"
      read -n 1 -p "Node.js is not installed, do you want to install it [Y/n]? " installNode
      installNode=${installNode:-"Y"}
      if [[ "$installNode" == "y" || "$installNode" == "Y" ]]; then
        echo "Installing Node.js..."
        curl -0 -L -k -s https://npmjs.org/install.sh | sudo npm_debug=1 bash
      else
        exit 1
      fi
      echo
    }

    npm=$(npm info less version 2>/dev/null)
    if [ -z "$npm" ]; then
      echo
      local installLess="N"
      read -n 1 -p "Less is not installed, do you want to install it [Y/n]? " installLess
      installLess=${installLess:-"Y"}
      if [[ "$installLess" == "y" || "$installLess" == "Y" ]]; then
        echo "Installing Less..."
        sudo npm install -g less
      else
        exit 1
      fi
    fi

		echo "Compiling Less files."
		echo

		for cartridge in "${cartridges[@]}"; do
			echo
			local cartPath=$(scp_cartridge_path "$cartridge")
			cd ${homedir}/${cartPath}
			echo ${cartridge}

			if [ -d ${homedir}/${cartPath}/cartridge/static ]; then

				file_list=()
				while IFS= read -d $'\0' -r file; do
					file_list=("${file_list[@]}" "$file")
				done < <(find "${homedir}/${cartPath}/cartridge/static" -name "*.less" -print0)

				cd ${deploydir}/bin
				for file in "${file_list[@]}" ; do
					echo "Compiling SCSS $file"

					lessc -x $file:${file%.*}.css
				done

			fi

		done
	fi
}
