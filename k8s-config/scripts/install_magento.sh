#!/usr/bin bash

Green='\033[0;32m'
NC='\033[0m'
DB_NAME='magento2ee'
DB_USER='magento@magento2ee'
DB_PASS='123123QqQ'
DP_HOST='magento2ee.mysql.database.azure.com'
MAGENTO_URL='104.208.39.182:8087'
MAGENTO_DIR='magento2ce'

cd $MAGENTO_DIR
composer install
cd ..

mysql -h${DP_HOST} -u${DB_USER} -p${DB_PASS} -e "DROP database IF EXISTS ${DB_NAME}; Create database if not exists ${DB_NAME};"
echo -e "Create DB ${Green}COMPLETED${NC}"
cd $MAGENTO_DIR
php bin/magento setup:install --language=en_US --timezone=America/Los_Angeles --currency=USD --db-host=${DP_HOST} --db-name=${DB_NAME} --db-user=${DB_USER} --db-password=${DB_PASS} --use-secure=0 --use-secure-admin=0 --use-rewrites=1 --admin-use-security-key=0 --backend-frontname=admin --base-url=http://${MAGENTO_URL}/ --base-url-secure=https://${MAGENTO_URL}/ --admin-user=admin --admin-password=123123q --admin-email=admin@example.com --admin-firstname=John --admin-lastname=Doe
chmod -R 777 var pub/static
rm -rf var/* pub/static/*
echo "Permissins was seted"
mysql -h${DP_HOST} -u${DB_USER} -p${DB_PASS} -D "${DB_NAME}" -e "UPDATE core_config_data SET value=0 WHERE path='admin/security/use_form_key';"
mysql -h${DP_HOST} -u${DB_USER} -p${DB_PASS} -D "${DB_NAME}" -e "INSERT INTO core_config_data (scope,scope_id,path,value) VALUES ('default',0,'admin/security/session_lifetime', 99999),('default',0,'admin/security/admin_account_sharing',1);"
echo "BD was updated"
php bin/magento setup:static-content:deploy -f
