for s in $(cat .secrets | jq -r "to_entries|map(\"\(.key)=\(.value|tostring)\")|.[]" ); do
	export $s
done
