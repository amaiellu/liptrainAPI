#!/bin/bash

set -euo pipefail

# Make sure these values are correct for your environment
resourceGroup="liraDev"
appName="liptrainAPI"
location="EastUs" 

# Change this if you are using your own github repository
gitSource="https://github.com/amaiellu/liptrainAPI.git"

# Make sure connection string variable is set

if [[ -z "${SQLAZURECONNSTR_WWIF:-}" ]]; then
	echo "Plase export Azure SQL connection string:";
    echo "export SQLAZURECONNSTR_WWIF=\"DRIVER={ODBC Driver 17 for SQL Server};SERVER=liptrainserver.database.windows.net;DATABASE=liptrainDB;UID=restAPI;PWD=8s0v0AYIB7o\"";
	exit 1;
fi

echo "Creating Application Service Plan...";
az appservice plan create \
    -g $resourceGroup \
    -n "linux-plan" \
    --sku S1 \
    --is-linux

echo "Creating Application Insight..."
az resource create \
    -g $resourceGroup \
    -n $appName-ai \
    --resource-type "Microsoft.Insights/components" \
    --properties '{"Application_Type":"web"}'

echo "Reading Application Insight Key..."
aikey=`az resource show -g $resourceGroup -n $appName-ai --resource-type "Microsoft.Insights/components" --query properties.InstrumentationKey -o tsv`

echo "Creating Web Application...";
az webapp create \
    -g $resourceGroup \
    -n $appName \
    --plan "linux-plan" \
    --runtime "PYTHON|3.8" \
    --deployment-source-url $gitSource \
    --deployment-source-branch master

echo "Configuring Connection String...";
az webapp config connection-string set \
    -g $resourceGroup \
    -n $appName \
    --settings WWIF="$SQLAZURECONNSTR_WWIF" \
    --connection-string-type=SQLAzure

echo "Configuring Application Insights...";
az webapp config appsettings set \
    -g $resourceGroup \
    -n $appName \
    --settings APPINSIGHTS_KEY="$aikey"

echo "Done."