
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