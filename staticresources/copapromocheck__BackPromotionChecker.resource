{
  "recordTypeMap": {},
  "RecordSetBundles": [
    {
      "Records": [
        {
          "attributes": {
            "type": "copado__ExtensionConfiguration__c",
            "url": "/services/data/v60.0/sobjects/copado__ExtensionConfiguration__c/a1u7Q000001Oj5RQAS"
          },
          "Id": "a1u7Q000001Oj5RQAS",
          "Name": "BackPromotionChecker",
          "copado__AcceptanceCriteria__c": "{}",
          "copado__Active__c": true,
          "copado__ExtensionApplication__c": "Test",
          "copado__Details__c": null,
          "copado__ExtensionTool__c": "BackPromotionChecker",
          "copado__TestType__c": "Process enforcement"
        }
      ],
      "ObjectType": "copado__ExtensionConfiguration__c"
    },
    {
      "Records": [
        {
          "attributes": {
            "type": "copado__JobTemplate__c",
            "url": "/services/data/v60.0/sobjects/copado__JobTemplate__c/a0t7Q000008XGUQQA4"
          },
          "Id": "a0t7Q000008XGUQQA4",
          "Name": "BackPromotionChecker",
          "copado__ApiName__c": "BackPromotionChecker_1",
          "copado__Description__c": "<p>Step to call a Flow and calculate the user stories behind for the environment. Over 0 it will fail</p>",
          "copado__Type__c": "Custom",
          "copado__Version__c": 1
        }
      ],
      "ObjectType": "copado__JobTemplate__c"
    },
    {
      "Records": [
        {
          "attributes": {
            "type": "copado__JobStep__c",
            "url": "/services/data/v60.0/sobjects/copado__JobStep__c/a0s7Q000000uClbQAE"
          },
          "Id": "a0s7Q000000uClbQAE",
          "Name": "Check Environment for Pending Back-Promotions",
          "copado__ApiName__c": "BackPromotionChecker_1_Check Environment for Pending Back-Promotions_0",
          "copado__ConfigJson__c": "{\"flowName\":\"copapromocheck.BackPromotionCheckerBeforePromotion\",\"parameters\":[{\"name\":\"promotionId\",\"value\":\"{$Context.JobExecution__r.Promotion__c}\"},{\"name\":\"pipelineId\",\"value\":\"{$Context.JobExecution__r.Promotion__r.copado__Project__r.copado__Deployment_Flow__c}\"},{\"name\":\"sourceEnvironmentId\",\"value\":\"{$Context.JobExecution__r.Promotion__r.copado__Source_Environment__c}\"},{\"name\":\"isBackPromotion\",\"value\":\"{$Context.JobExecution__r.Promotion__r.copado__Back_Promotion__c}\"},{\"name\":\"deploymentDryRun\",\"value\":\"{$Context.JobExecution__r.DataJson.deploymentDryRun}\"},{\"name\":\"BACK_PROMOTIONS_ALLOWED\",\"value\":\"{$Property.BACK_PROMOTIONS_ALLOWED}\"}]}",
          "copado__CustomType__c": "Salesforce Flow",
          "copado__JobTemplate__c": "a0t7Q000008XGUQQA4",
          "copado__Order__c": 0,
          "copado__Parent_Owner_Id__c": "0057Q000000MfOQ",
          "copado__Type__c": "Flow"
        }
      ],
      "ObjectType": "copado__JobStep__c"
    }
  ],
  "blobsByUID": {}
}