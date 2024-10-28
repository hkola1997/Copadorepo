{
    "recordTypeMap": {},
    "RecordSetBundles": [
      {
        "Records": [
          {
            "attributes": {
              "type": "copado__ExtensionConfiguration__c",
              "url": "/services/data/v60.0/sobjects/copado__ExtensionConfiguration__c/a0iWV0000004NR3YAM"
            },
            "copado__AcceptanceCriteria__c": "{}",
            "copado__Active__c": true,
            "copado__ExtensionApplication__c": "Test",
            "copado__ExtensionTool__c": "CodeScan",
            "copado__Status__c": "Inactive",
            "copado__TestType__c": "CodeScan",
            "copado__copadoQuality__Requires_Sync__c": false,
            "Id": "a0iWV0000004NR3YAM",
            "LastReferencedDate": "2024-02-12T09:21:59.000+0000",
            "LastViewedDate": "2024-02-12T09:21:59.000+0000",
            "Name": "Code Scan"
          }
        ],
        "ObjectType": "copado__ExtensionConfiguration__c"
      },
      {
        "Records": [
          {
            "attributes": {
              "type": "copado__Function__c",
              "url": "/services/data/v60.0/sobjects/copado__Function__c/a0oWV0000000VlNYAU"
            },
            "copado__API_Name__c": "Run_Code_Scan_1",
            "copado__Image_Name__c": "xieeoka6kixfqik4tc07hnxxigf50h-sfdx-codescan-plugin:v1.0",
            "copado__Options__c": "[ ]",
            "copado__Parameters__c": "[ {\n  \"name\" : \"SERVER\",\n  \"defaultValue\" : \"\"\n}, {\n  \"name\" : \"PROJECT_ID\",\n  \"defaultValue\" : \"\"\n}, {\n  \"name\" : \"TOKEN\",\n  \"defaultValue\" : \"\"\n}, {\n  \"name\" : \"BRANCH\",\n  \"defaultValue\" : \"\"\n}, {\n  \"name\" : \"ORGANIZATION\",\n  \"defaultValue\" : \"\"\n}, {\n  \"name\" : \"git_json\",\n  \"defaultValue\" : \"{$Context.Repository.Credential}\"\n}, {\n  \"name\" : \"USER_STORY\",\n  \"defaultValue\" : \"\"\n} ]",
            "copado__Script__c": "#originBranch=$(jq -r '.originBranch' <<< $branchesAndFileIdJson)\n#BRANCH=\"$originBranch\"\n\n#echo \"param branchesAndFileIdJson =  $branchesAndFileIdJson\"\n#echo \"param originBranch = $originBranch\"\n\necho \"param TOKEN = $TOKEN\"\necho \"param SERVER = $SERVER\"\necho \"param PROJECT_ID = $PROJECT_ID\"\necho \"param ORGANIZATION = $ORGANIZATION\"\necho \"param BRANCH = $BRANCH\"\n\nif test -z \"${BRANCH:-}\"; then\n    BRANCH=\"feature/$USER_STORY\"\nfi\necho \"param BRANCH = $BRANCH\"\n\ncopado -p \"cloning repo...\"\ncopado-git-get $BRANCH\ncopado -p \"running codescan...\"\nexitCode=0\nsfdx codescan:run --token=$TOKEN --server=$SERVER --projectkey=$PROJECT_ID --organization=$ORGANIZATION -Dsonar.branch.name=$BRANCH --json 2>&1 | tee /tmp/result.json \\\n    || exitCode=$?\necho \"Codescan completed. exit code: $exitCode\"\ncopado -u /tmp/result.json\nexit $exitCode",
            "copado__Timeout__c": 300,
            "copado__Type__c": "Custom",
            "copado__Version__c": "1",
            "copado__Worker_Size__c": "S",
            "Id": "a0oWV0000000VlNYAU",
            "LastReferencedDate": "2024-02-12T08:27:50.000+0000",
            "LastViewedDate": "2024-02-12T08:27:50.000+0000",
            "Name": "Run CodeScan"
          },
          {
            "attributes": {
              "type": "copado__Function__c",
              "url": "/services/data/v60.0/sobjects/copado__Function__c/a0oWV0000000VlOYAU"
            },
            "copado__ApexClass__c": "EvaluateCodeScanResult",
            "copado__API_Name__c": "Run_CodeScan_QIF",
            "copado__Callback_Type__c": "ApexClass",
            "copado__Description__c": "For the Quality Gate Engine only",
            "copado__Image_Name__c": "xieeoka6kixfqik4tc07hnxxigf50h-sfdx-codescan-plugin:v1.0",
            "copado__Options__c": "[ ]",
            "copado__Parameters__c": "[ {\n  \"name\" : \"SERVER\",\n  \"defaultValue\" : \"\"\n}, {\n  \"name\" : \"PROJECT_ID\",\n  \"defaultValue\" : \"\"\n}, {\n  \"name\" : \"TOKEN\",\n  \"defaultValue\" : \"\"\n}, {\n  \"name\" : \"ORGANIZATION\",\n  \"defaultValue\" : \"\"\n}, {\n  \"name\" : \"git_json\",\n  \"defaultValue\" : \"{$Context.Repository.Credential}\"\n}, {\n  \"name\" : \"branchesAndFileIdJson\",\n  \"defaultValue\" : \"{$Job.PrevStep.ResultDataJson__c}\"\n} ]",
            "copado__Script__c": "originBranch=$(jq -r '.originBranch' <<< $branchesAndFileIdJson)\nBRANCH=\"$originBranch\"\n\necho \"param branchesAndFileIdJson =  $branchesAndFileIdJson\"\necho \"param originBranch = $originBranch\"\necho \"param TOKEN = $TOKEN\"\necho \"param SERVER = $SERVER\"\necho \"param PROJECT_ID = $PROJECT_ID\"\necho \"param ORGANIZATION = $ORGANIZATION\"\necho \"param BRANCH = $BRANCH\"\n\ncopado -p \"cloning repo...\"\ncopado-git-get $BRANCH\ncopado -p \"running codescan...\"\nexitCode=0\nsfdx codescan:run --token=$TOKEN --server=$SERVER --projectkey=$PROJECT_ID --organization=$ORGANIZATION -Dsonar.branch.name=$BRANCH --json 2>&1 | tee /tmp/result.json \\\n    || exitCode=$?\necho \"Codescan completed. exit code: $exitCode\"\ncopado -u /tmp/result.json\nexit $exitCode",
            "copado__Timeout__c": 300,
            "copado__Type__c": "Custom",
            "copado__Version__c": "1",
            "copado__Worker_Size__c": "S",
            "Id": "a0oWV0000000VlOYAU",
            "LastReferencedDate": "2024-02-12T08:27:50.000+0000",
            "LastViewedDate": "2024-02-12T08:27:50.000+0000",
            "Name": "Run CodeScan QIF"
          }
        ],
        "ObjectType": "copado__Function__c"
      },
      {
        "Records": [
          {
            "attributes": {
              "type": "copado__JobTemplate__c",
              "url": "/services/data/v60.0/sobjects/copado__JobTemplate__c/a0xWV0000000C2nYAE"
            },
            "copado__ApiName__c": "Run_CodeScan_User_Story",
            "copado__Type__c": "Custom",
            "copado__Version__c": 1,
            "Id": "a0xWV0000000C2nYAE",
            "LastReferencedDate": "2024-02-12T08:28:24.000+0000",
            "LastViewedDate": "2024-02-12T08:28:24.000+0000",
            "Name": "Run CodeScan from User Story"
          },
          {
            "attributes": {
              "type": "copado__JobTemplate__c",
              "url": "/services/data/v60.0/sobjects/copado__JobTemplate__c/a0xWV0000000C2oYAE"
            },
            "copado__ApiName__c": "Run_CodeScan_QIF_1",
            "copado__Type__c": "Custom",
            "copado__Version__c": 1,
            "Id": "a0xWV0000000C2oYAE",
            "LastReferencedDate": "2024-02-12T09:29:07.000+0000",
            "LastViewedDate": "2024-02-12T09:29:07.000+0000",
            "Name": "Run CodeScan QIF"
          }
        ],
        "ObjectType": "copado__JobTemplate__c"
      },
      {
        "Records": [
          {
            "attributes": {
              "type": "copado__JobStep__c",
              "url": "/services/data/v60.0/sobjects/copado__JobStep__c/a0wWV0000000JvVYAU"
            },
            "copado__ApiName__c": "CodeScan_Run CodeScan_1",
            "copado__ConfigJson__c": "{\"functionName\":\"Run_Code_Scan_1\",\"parameters\":[{\"name\":\"SERVER\",\"value\":\"{$Pipeline.Property.CS_SERVER}\"},{\"name\":\"PROJECT_ID\",\"value\":\"{$Pipeline.Property.CS_PROJECT_ID}\"},{\"name\":\"TOKEN\",\"value\":\"{$Pipeline.Property.CS_TOKEN}\"},{\"name\":\"BRANCH\",\"value\":\"\"},{\"name\":\"ORGANIZATION\",\"value\":\"{$Pipeline.Property.CS_ORGANIZATION}\"},{\"name\":\"git_json\",\"value\":\"{$Context.Repository.Credential}\"},{\"name\":\"USER_STORY\",\"value\":\"{$Job.ExecutionParent.Name}\"}]}",
            "copado__CustomType__c": "Function",
            "copado__IsSkipped__c": false,
            "copado__JobTemplate__c": "a0xWV0000000C2nYAE",
            "copado__Order__c": 3,
            "copado__Type__c": "Function",
            "Id": "a0wWV0000000JvVYAU",
            "Name": "Run CodeScan"
          },
          {
            "attributes": {
              "type": "copado__JobStep__c",
              "url": "/services/data/v60.0/sobjects/copado__JobStep__c/a0wWV0000000JvWYAU"
            },
            "copado__ApiName__c": "Run CodeScan_1_Execute PMD_3",
            "copado__ConfigJson__c": "{\"functionName\":\"Run_CodeScan_QIF\",\"parameters\":[{\"name\":\"SERVER\",\"value\":\"{$Pipeline.Property.CS_SERVER}\"},{\"name\":\"PROJECT_ID\",\"value\":\"{$Pipeline.Property.CS_PROJECT_ID}\"},{\"name\":\"TOKEN\",\"value\":\"{$Pipeline.Property.CS_TOKEN}\"},{\"name\":\"ORGANIZATION\",\"value\":\"{$Pipeline.Property.CS_ORGANIZATION}\"},{\"name\":\"git_json\",\"value\":\"{$Context.Repository.Credential}\"},{\"name\":\"branchesAndFileIdJson\",\"value\":\"{$Context.Apex.copadoQuality.RetrieveBranchesAndFileIdForPmdScan}\"}]}",
            "copado__CustomType__c": "Function",
            "copado__IsSkipped__c": false,
            "copado__JobTemplate__c": "a0xWV0000000C2oYAE",
            "copado__Order__c": 4,
            "copado__Type__c": "Function",
            "Id": "a0wWV0000000JvWYAU",
            "Name": "Execute CodeScan"
          },
          {
            "attributes": {
              "type": "copado__JobStep__c",
              "url": "/services/data/v60.0/sobjects/copado__JobStep__c/a0wWV0000000JvYYAU"
            },
            "copado__ApiName__c": "Run CodeScan_1_Set Repository For Scan_1",
            "copado__ConfigJson__c": "{\"flowName\":\"SetRepositoryForScan\",\"parameters\":[{\"name\":\"testIds\",\"value\":\"{$Context.JobExecution__r.DataJson.testIds}\"},{\"name\":\"jobStepToUpdate\",\"value\":\"{$Job.Step.Execute CodeScan.Id}\"}]}",
            "copado__CustomType__c": "Salesforce Flow",
            "copado__IsSkipped__c": false,
            "copado__JobTemplate__c": "a0xWV0000000C2oYAE",
            "copado__Order__c": 1,
            "copado__Type__c": "Flow",
            "Id": "a0wWV0000000JvYYAU",
            "Name": "Set Repository For Scan"
          },
          {
            "attributes": {
              "type": "copado__JobStep__c",
              "url": "/services/data/v60.0/sobjects/copado__JobStep__c/a0wWV0000000JvZYAU"
            },
            "copado__ApiName__c": "Run_CodeScan_QIF_1_Get Parent Execution Context_5",
            "copado__ConfigJson__c": "{\"flowName\":\"Carry_Orchastrator_Job_Execution_Context\",\"parameters\":[{\"name\":\"jobExecutionId\",\"value\":\"{$Job.FirstStep.copado__JobExecution__c}\"},{\"name\":\"testIds\",\"value\":\"{$Context.JobExecution__r.DataJson.testIds}\"},{\"name\":\"consolidatedResultId\",\"value\":\"{$Context.JobExecution__r.DataJson.resultId}\"}]}",
            "copado__CustomType__c": "Salesforce Flow",
            "copado__IsSkipped__c": false,
            "copado__JobTemplate__c": "a0xWV0000000C2oYAE",
            "copado__Order__c": 2,
            "copado__Type__c": "Flow",
            "Id": "a0wWV0000000JvZYAU",
            "Name": "Get Parent Execution Context"
          }
        ],
        "ObjectType": "copado__JobStep__c"
      }
    ],
    "blobsByUID": {}
}
