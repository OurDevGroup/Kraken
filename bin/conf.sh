string="string"
bool="bool"

write_status() {
	local file="${deploydir}/working/status"
	
	if [ ! -f $file ]; then
		touch $file
	fi

	echo -e $1 > $file

	return
}

read_status() {
	local file="${deploydir}/working/status"
	
	if [ ! -f $file ]; then
		touch $file
	fi

	local status="$( cat $file )";

	echo $status

	return
}

write_conf() {
	local file="${deploydir}/conf/$1.conf"
	local setting="$2"
	local value="$3"

	if [ ! -f $file ]; then
		touch $file
	fi

	local confout=""
	while IFS='' read -r line || [[ -n $line ]]; do
		local pp="$( cut -d '=' -f 1 <<< "$line" )";
		local vv="$( cut -d '=' -f 2- <<< "$line" )";
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
			echo $vv | tr -d '\n' | tr -d '\r'
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
			return
		fi
	fi

	echo $4
	return
}

function trim {
    echo $*
}

# $1 conf type
# $2 variable_name
# $3 variable_type
# $4 variable_default
# $5 prompt
# $6 required
# $7 passphrase
# $8 store

prompt() {
	if [ "$3" == "string" ]; then
		if [ "$7" == "" ]; then
			local existingVal=$(read_conf $1 $2 $4)
		else
			local existingVal=$(read_conf_enc $1 $2 $7)
		fi

		if [ $ReleaseTheKraken == true ] && [ "$existingVal" != "" ]; then
			echo "$existingVal"
			return
		fi
	else
		local t_existingVal=$(read_conf $1 $2 $4)
		if [ "$t_existingVal" == "true" ]; then
			local existingVal=true
		else
			local existingVal=false
		fi

		if [ $ReleaseTheKraken == true ]; then
			echo $existingVal | tr -d '\n'
			return
		fi
	fi

    local valProvided=false
    while ! $valProvided; do
			if [ "$3" == "string" ]; then
				if [ "$existingVal" != "" ]; then
					local dispVal=$existingVal
					if [ "$7" == "" ]; then
						local dispValLen=${#existingVal}
						if [ ${dispValLen} -gt 40 ]; then
							local dispVal="$(trim ${existingVal:0:15}).....$(trim ${existingVal:(-25)})"
						fi
					else
						local dispVal="stored password"
					fi
					if [ "$7" == "" ]; then
						read -p "$5 [$dispVal]: " newval
					else
						read -p "$5 [$dispVal]: " -s newval
					fi
				else
					if [ "$7" == "" ]; then
						read -p "$5: " newval
					else
						read -p "$5: " -s newval
					fi
				fi
		else #if [ "$3" == "string" ]; then
			if [ $existingVal == true ]; then
				read -n 1 -p "$5 [Y/n]: " yn_newval
				yn_newval=${yn_newval:-Y}
			else
				read -p "$5 [y/N]: " yn_newval
				yn_newval=${yn_newval:-N}
			fi
		fi

		if [[ "$3" == "string" && "$existingVal" != "" ]]; then
			newval=${newval:-$existingVal}
		elif [ "$3" == "bool" ]; then
			if [ "$(upper "$yn_newval")" == "Y" ]; then
				newval=true
			else
				newval=false
			fi
	  fi

		if [[ "$newval" == "\r" && required ]]; then
        echo "$2 cannot be empty!"
    else
        valProvided=true
    fi
	done

	if [ "$8" == "" ] || [ $8 == true ]; then

		if [ "$7" == "" ]; then
			write_conf $1 $2 "$newval"
		else
			write_conf_enc $1 $2 "$newval" $7
		fi
	fi

	echo $newval
	return
}

# $1 conf type
# $2 variable_name
# $3 variable_type
# $4 variable_default
# $5 prompt
# $6 required
# $7 passphrase
# $8 store

secure_prompt() {
	local secVal=$(prompt "$1" "$2" "$3" "$4" "$5" "$6" "$7" $8)
	echo $secVal
	return
}
