source export.sh
az login --service-principal --username $appId --password $password --tenant $tenant
az storage blob directory upload -c $storageContainerName \
	--account-name $storageAccountName \
	-s "/content" \
	-d "/content" \
	--recursive \
	--auth-mode login

