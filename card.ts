
param appName string = 'aidaily${uniqueString(resourceGroup().id)}'
param location string = resourceGroup().location

resource st 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: toLower('${appName}st')
  location: location
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
}

resource plan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: '${appName}-plan'
  location: location
  sku: { name: 'Y1', tier: 'Dynamic' }
}

resource func 'Microsoft.Web/sites@2023-12-01' = {
  name: '${appName}-func'
  location: location
  kind: 'functionapp'
  identity: { type: 'SystemAssigned' }
  properties: {
    siteConfig: {
      appSettings: [
        { name: 'FUNCTIONS_WORKER_RUNTIME', value: 'node' },
        { name: 'WEBSITE_RUN_FROM_PACKAGE', value: '1' },
        { name: 'BING_KEY', value: '' },
        { name: 'MKT', value: 'en-US' },
        { name: 'TABLE_NAME', value: 'ConversationRefs' }
      ]
    }
    serverFarmId: plan.id
  }
}
