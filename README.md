# liptrainAPI

This is the currently available API endpoints to the sql database for the liptrain project. The development version can be queried via https://liptrainapi-dev.azurewebsites.net. This connects to a development version of the database.

The liptrain.sql file contains the stored procedures currently available in the database, which are called by the API. 

The webservice was developed using the Flask framework. 

use 

pip install -r requirements.txt 

to install required packages. 


The structure of the database is as follows: 

![image](https://user-images.githubusercontent.com/15605232/121098824-b048a380-c7c4-11eb-89f9-24ef5dcd7417.png)


To connect with the database in SSMS and be able to query and view available data, use 

servername: liradb-dev.database.windows.net
user:
password:

Under options--> connection properties 

database name: liptrainDB_Dev

Please note that port 1433 needs to be accessible through any firewalls your connection is behind in order to connect to the database via ssms.

Documentation for using ssms:

https://docs.microsoft.com/en-us/azure/azure-sql/database/connect-query-ssms


You have also been granted access to a development version of the blob storage account, which should now be visible to you in the azure portal. The SQL database contains the metadata and path in  blob storage at which each video can be found. 

Documentation for interacting with blob storage:

https://docs.microsoft.com/en-us/azure/storage/blobs/storage-quickstart-blobs-python

You have also been added to a bing speech to text service account. Documentation for Bing speech to text api:

https://docs.microsoft.com/en-us/azure/cognitive-services/speech-service/get-started-speech-to-text?tabs=windowsinstall&pivots=programming-language-python


You may need specific information from me as you progress (connection strings, subscription keys etc). Let me know if you hit such a block. 










